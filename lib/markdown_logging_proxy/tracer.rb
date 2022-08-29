module MarkdownLoggingProxy
  class Tracer
    attr_reader :target, :logger, :ignore, :proxy

    def initialize(
        target:,
        proxy:,
        logger: nil,
        ignore: [],
        proxy_response: [],
        proxy_options: {}
      )
      @target = target
      @logger = logger
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

    private

    def log_call_signature(meth, args, &blk)
      return if ignore.member?(meth)
      logger.log :info, 1, <<~MSG.chomp
        Calling `#{meth}` on #{MarkdownLogger.id_object(target)}

        Arguments:

        #{MarkdownLogger.inspect_object(args, false)}

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

        Proxy from `#{meth}` on #{MarkdownLogger.id_object(target)}

        Proxy for:

        #{MarkdownLogger.inspect_object(response)}
      MSG
      Proxy.new(**@proxy_options.merge(
        target: response,
        location: logger,
        proxy_response: @proxy_response,
        ignore: @ignore,
      ))
    end

    def log_and_proxy_block(meth, blk)
      return if blk.nil?
      logger_ref = self.logger
      target_ref = self.target
      proc do |*args|
        logger_ref.log :info, 2, <<~MSG.chomp
          Yield to block in `#{meth}` on #{MarkdownLogger.id_object(target_ref)}

          Arguments:

          #{MarkdownLogger.inspect_object(args, false)}
        MSG
        instance_exec(*args, &blk).tap do |response|
          logger_ref.log :info, 3, <<~MSG.chomp
            Response from block in `#{meth}`

            #{MarkdownLogger.inspect_object(response)}
          MSG
        end
      end
    end

    def log_and_reraise_error(meth, error)
      logger.log :error, 2, <<~MSG.chomp
        Error in `#{meth}`

        Type: #{error.class}

        #{MarkdownLogger.inspect_object(error)}
      MSG
      raise error
    end

    def log_response(meth, response)
      return if ignore?(meth)
      logger.log :info, 2, <<~MSG.chomp
        `#{meth}` response

        #{MarkdownLogger.inspect_object(response)}
      MSG
    end
  end
end
