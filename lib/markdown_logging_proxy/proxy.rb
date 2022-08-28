module MarkdownLoggingProxy
  # frozen_string_literal: true

  require 'logger'
  require 'securerandom'
  require 'pp'
  require 'time'

  class Proxy

    def initialize(
        to_proxy = nil,
        target: nil,
        location: STDOUT,
        backtrace: true, # regex/true/false backtrace control
        ignore: [], # methods we shouldn't log/proxy
        proxy_response: [], # methods we should return a proxy for
        overwrite: [] # methods defined on Object we should overwrite
      )
      @ignore = (ignore + proxy_response).uniq
      @proxy_response = proxy_response
      @target = to_proxy || target
      raise ArgumentError, "Missing required proxy target" unless @target
      @logger = MarkdownLogger.new(location, backtrace: backtrace)
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
      @logger.log :info, 1, <<~MSG
        Calling `#{meth}`

        Arguments:

        #{MarkdownLogger.inspect_object(args)}

        Block? #{block_given? ? 'Yes' : 'No'}
        #{@logger.inspect_backtrace}
      MSG

      __proxy_response(meth, @target.public_send(meth, *args, &__proxy_block(meth, blk))).tap do |response|
        @logger.log :info, 2, <<~MSG
          `#{meth}` Response

          #{MarkdownLogger.inspect_object(response)}
        MSG
      end
    rescue StandardError => e
      @logger.log :error, 2, <<~MSG
        Error in `#{meth}`

        Type: #{e.class}

        #{MarkdownLogger.inspect_object(e)}
      MSG
      raise e
    end

    def __proxy_response(meth, response)
      return response unless @proxy_response.member?(meth)
      @logger.log :info, 3, <<~MSG
        Using proxied response for `#{meth}`

        Object to proxy:

        #{MarkdownLogger.inspect_object(response)}
      MSG
      self.class.new(target: response, logger: @logger)
    end

    def __proxy_block(meth, block)
      return if block.nil?
      logger = @logger
      proc do |*args|
        logger.log :info, 3, <<~MSG
          Yield to block in `#{meth}`

          Arguments:

          #{MarkdownLogger.inspect_object(args)}
        MSG
        block.call(*args).tap do |response|
          logger.log :info, 4, <<~MSG
            Response from block in `#{meth}`

            #{MarkdownLogger.inspect_object(response)}
          MSG
        end
      end
    end
  end
end
