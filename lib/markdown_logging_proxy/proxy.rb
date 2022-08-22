module MarkdownLoggingProxy
  # frozen_string_literal: true

  require 'logger'
  require 'securerandom'
  require 'pp'
  require 'time'

  class Proxy

    def initialize(
        target:,
        logger: nil,
        location: STDOUT,
        backtrace: /projects/, # regex/true/false backtrace control
        ignore: [], # methods we shouldn't proxy
        proxy_response: [], # methods we should return a proxy for
        overwrite: [] # methods defined on Object we should overwrite
      )
      @ignore = (ignore + proxy_response).uniq
      @proxy_response = proxy_response
      @target = target
      @logger = logger || __setup_logger(location)
      @backtrace = backtrace
      overwrite.each do |meth|
        define_method(meth) do |*args, &blk|
          __trace_method(meth, args, &blk)
        end
      end
    end

    def method_missing(meth, *args, &blk)
      __trace_method(meth, args, &blk)
    end

    private

    def __trace_method(meth, args, &blk)
      __log :info, meth, 2, <<~MSG
        Calling `#{meth}`

        Arguments:

        #{__inspect_object(args)}

        Block? #{block_given? ? 'Yes' : 'No'}
        #{__display_backtrace}
      MSG

      __proxy_response(meth, @target.public_send(meth, *args, &__proxy_block(meth, blk))).tap do |response|
        __log :info, meth, <<~MSG
          `#{meth}` Response

          #{__inspect_object(response)}
        MSG
      end
    rescue StandardError => e
      __log :error, meth, <<~MSG
        Error in `#{meth}`

        Type: #{e.class}

        #{__inspect_object(e)}
      MSG
      raise e
    end

    def __display_backtrace(ignore = 3)
      displayed_trace =
        case @backtrace
        when true then caller(ignore)
        when Regexp then caller(ignore).grep(@backtrace)
        end
      displayed_trace.map { |l| "* #{l.chop}`" }.join("\n") if displayed_trace
    end

    def __log(level, meth, heading = 3, msg)
      return if @ignore.member?(meth)
      @heading_level = heading
      @logger.send(level, msg)
    end

    def __proxy_response(meth, response)
      return response unless @proxy_response.member?(meth)
      __log :info, nil, <<~MSG
        Using proxied response for `#{meth}`

        Object to proxy:

        #{__inspect_object(response)}
      MSG
      self.class.new(target: response, logger: @logger)
    end

    def __proxy_block(meth, block)
      return if block.nil?
      logger = @logger
      proc do |*args|
        logger.info <<~MSG
          Yield to block in `#{meth}`

          Arguments:

          #{__inspect_object(args)}
        MSG
        block.call(*args).tap do |response|
          logger.info <<~MSG
            Response from block in `#{meth}`

            #{__inspect_object(response)}
          MSG
        end
      end
    end

    def __inspect_object(obj)
      ['```ruby', obj.pretty_inspect.chomp, '```'].join("\n")
    end

    def __setup_logger(log_location)
      Logger.new(log_location).tap do |logger|
        logger.formatter = proc do |severity, time, _, msg|
          "#{'#' * @heading_level} #{severity} in #{Process.pid} at #{time.iso8601} -- #{msg}\n\n"
        end
      end
    end
  end

end
