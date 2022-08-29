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

    def inspect_object(obj, show_id: true)
      obj_str =
        case inspect_method
        when :inspect then obj.inspect
        when :object_id then object_id(obj)
        when :pretty_inpect
          [obj.pretty_inspect.chomp].tap do |lines|
            lines.prepend "# #{object_id(obj)}" if show_id
          end.join("\n")
        else
          obj.send(inspect_method)
        end
      ['```ruby', obj_str, '```'].join("\n")
    end

    def id_object(object)
      # #<Object:0xe140>
      "`#<#{object.class}:0x#{object.object_id.to_s(16)}>`"
    end

    private

    def log_call_signature(meth, args, &blk)
      return if ignore.member?(meth)
      logger.log :info, 1, <<~MSG.chomp
        Calling `#{meth}` on #{id_object(target)}

        Arguments:

        #{inspect_object(args, show_id: false)}

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

        Proxy from `#{meth}` on #{id_object(target)}

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
          Yield to block in `#{meth}` on #{tracer.id_object(tracer.target)}

          Arguments:

          #{tracer.inspect_object(args, show_id: false)}
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
