require 'logger'
require 'securerandom'
require 'pp'
require 'time'
module MarkdownLoggingProxy
  class MarkdownLogger
    def self.build(location, **options)
      return location if location.is_a?(MarkdownLogger)
      new(location, **options)
    end

    attr_reader :std_logger, :backtrace, :heading_level, :created_at

    def initialize(location, backtrace: true)
      @created_at = Time.now
      @std_logger = create_logger(location)
      @heading_level = 1
      @backtrace = backtrace
    end

    def log(level, heading = 3, msg)
      @heading_level = heading
      std_logger.send(level, msg)
    end

    def inspect_backtrace(ignore = 4)
      return unless backtrace
      lines =
        case backtrace
        when true then caller(ignore)
        when Regexp then caller(ignore).grep(backtrace)
        else
          []
        end
      <<~MSG.chomp

        Backtrace:

        #{lines.map { |l| "* #{l.chop}`" }.join("\n")}
      MSG
    end

    private

    def logger_instance(location)
      case location
      when Logger then location
      else
        Logger.new(location)
      end
    end

    def create_logger(location)
      logger_instance(location).tap do |logger|
        logger.formatter = markdown_formatter
      end
    end

    def markdown_formatter
      proc do |severity, time, __exec, msg|
        elapsed = Time.now - created_at
        "#{'#' * heading_level} #{severity} at +#{elapsed.round(5)} -- #{msg}\n\n"
      end
    end
  end
end
module MarkdownLoggingProxy
  # just a shortcut for Proxy.new
  def self.new(*args, **options)
    Proxy.new(*args, **options)
  end
end
module MarkdownLoggingProxy
  class Proxy
    DO_NOT_OVERWRITE = %i[__binding__ __id__ __send__ class extend]
    DEFAULT_OVERWRITES = Object.new.methods - DO_NOT_OVERWRITE

    def initialize(
        to_proxy = nil,
        target: nil,
        location: STDOUT,
        backtrace: true, # regex/true/false backtrace control
        inspect_method: :pretty_inspect,
        ignore: [], # methods we shouldn't log/proxy
        proxy_response: [], # methods we should return a proxy for
        overwrite: DEFAULT_OVERWRITES
      )
      @target = to_proxy || target
      @logger = MarkdownLogger.build(location, backtrace: backtrace)
      @tracer = Tracer.new(
        target: @target,
        proxy: self,
        logger: @logger,
        inspect_method: inspect_method,
        ignore: ignore,
        proxy_response: proxy_response,
        proxy_options: {
          overwrite: overwrite,
          backtrace: backtrace,
        }
      )
      overwrite.each do |meth|
        self.class.define_method(meth) do |*args, &blk|
          @tracer.trace(meth, args, &blk)
        end
      end
    end

    def method_missing(meth, *args, &blk)
      @tracer.trace(meth, args, &blk)
    end
  end
end
module MarkdownLoggingProxy
  class Tracer
    attr_reader :target, :logger, :ignore, :proxy, :inspect_method

    def initialize(
        target:,
        proxy:,
        logger: nil,
        inspect_method: :pretty_inspect,
        ignore: [],
        proxy_response: [],
        proxy_options: {}
      )
      @target = target
      @logger = logger
      @inspect_method = inspect_method
      @ignore = ignore
      @proxy_response = proxy_response
      @proxy_options = proxy_options
    end

    def trace(meth, args, &blk)
      log_call_signature(meth, args, &blk) unless ignore?(meth)
      log_and_proxy_response(meth, args, &blk)
    rescue StandardError => e
      log_and_reraise_error(meth, e)
    end

    def proxy_response?(meth)
      case @proxy_response
      when true, false then @proxy_response
      else
        @proxy_response.member?(meth)
      end
    end

    def ignore?(meth)
      @ignore.member?(meth)
    end

    def inspect_object(obj, args: false)
      obj_str =
        case inspect_method
        when :inspect then obj.inspect
        when :limited then limited_inspect(obj)
        when :id_object
          if args
            "[#{obj.map { |o| id_object(o) }.join(',')}]"
          else
            id_object(obj)
          end
        when :pretty_inpect
          [obj.pretty_inspect.chomp].tap do |lines|
            lines.prepend "# #{id_object(obj)}" unless args
          end.join("\n")
        else
          obj.send(inspect_method)
        end
      ['```ruby', obj_str, '```'].join("\n")
    end

    # recursive
    def limited_inspect(obj)
      case obj
      when Array
        "[#{obj.map { |o| limited_inspect(o) }.join(',')}]"
      when Hash
        # assumes keys are safe to .inspect
        insides = obj.each { |k, v| "#{k.inspect} => #{limited_inspect(v)}" }
        "{#{insides.join(', ')}}"
      when String, Symbol, Numeric, Class, true, false, nil
        truncated_inspect(obj)
      else
        id_object(obj)
      end
    end

    def id_object(object)
      # #<Object:0xe140>
      "#<#{object.class}:0x#{object.object_id.to_s(16)}>"
    end

    def truncated_inspect(obj, limit = 280)
      obj_str = obj.inspect
      obj_str = "#{obj_str.first(limit)}..." if obj_str.length > limit
      obj_str
    end

    private

    def log_call_signature(meth, args, &blk)
      return if ignore.member?(meth)
      logger.log :info, 1, <<~MSG.chomp
        Calling `#{meth}` on `#{id_object(target)}`

        Arguments:

        #{inspect_object(args, args: true)}

        Block given? #{block_given? ? 'Yes' : 'No'}
        #{logger.inspect_backtrace}
      MSG
    end

    def log_and_proxy_response(meth, args, &blk)
      response = target.public_send(meth, *args, &log_and_proxy_block(meth, blk))
      log_response(meth, response) unless ignore?(meth)
      return response unless proxy_response?(meth)
      logger.log :info, 3, <<~MSG.chomp
        Returning proxied response to `#{meth}`

        Proxy from `#{meth}` on `#{id_object(target)}`

        Proxy for:

        #{inspect_object(response)}
      MSG
      Proxy.new(**@proxy_options.merge(
        target: response,
        location: logger,
        inspect_method: inspect_method,
        proxy_response: @proxy_response,
        ignore: @ignore,
      ))
    end

    def log_and_proxy_block(meth, blk)
      return if blk.nil?
      tracer = self
      proc do |*args|
        tracer.logger.log :info, 2, <<~MSG.chomp
          Yield to block in `#{meth}` on `#{tracer.id_object(tracer.target)}`

          Arguments:

          #{tracer.inspect_object(args, args: true)}
        MSG
        instance_exec(*args, &blk).tap do |response|
          tracer.logger.log :info, 3, <<~MSG.chomp
            Response from block in `#{meth}`

            #{tracer.inspect_object(response)}
          MSG
        end
      end
    end

    def log_and_reraise_error(meth, error)
      logger.log :error, 2, <<~MSG.chomp
        Error in `#{meth}`

        Type: #{error.class}

        #{inspect_object(error)}
      MSG
      raise error
    end

    def log_response(meth, response)
      return if ignore?(meth)
      logger.log :info, 2, <<~MSG.chomp
        `#{meth}` response

        #{inspect_object(response)}
      MSG
    end
  end
end

