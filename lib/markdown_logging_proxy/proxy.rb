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
      @target = to_proxy || target
      raise ArgumentError, "Missing required proxy target" unless @target
      @logger = MarkdownLogger.build(location, backtrace: backtrace)
      @tracer = Tracer.new(
        target: @target,
        proxy: self,
        logger: @logger,
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
