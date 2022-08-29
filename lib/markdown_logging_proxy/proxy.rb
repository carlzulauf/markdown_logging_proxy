module MarkdownLoggingProxy
  class Proxy
    # Object methods that should be proxied but won't hit method_missing
    DEFAULT_OVERWRITES = %i[
      ! != !~ <=> == === =~
      clone display dup enum_for eql? equal? freeze frozen? hash inspect
      is_a? itself kind_of? nil? taint tainted? tap then to_enum to_s
      trust untaint unstrust untrusted? yield_self
    ]

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
