module MarkdownLoggingProxy
  class Proxy
    DO_NOT_OVERWRITE = %i[__binding__ __id__ __send__ class extend]
    DEFAULT_OVERWRITES = Object.new.methods - DO_NOT_OVERWRITE

    def initialize(
        to_proxy = nil,
        target: nil,
        location: STDOUT,
        backtrace: true, # regex/true/false backtrace control
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
