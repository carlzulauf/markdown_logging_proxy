module MarkdownLoggingProxy
  class MarkdownLogger
    def self.inspect_object(object)
      ['```ruby', object.pretty_inspect.chomp, '```'].join("\n")
    end

    attr_reader :std_logger, :backtrace

    def initialize(location, backtrace: true)
      @std_logger = create_logger(location)
      @heading_level = 1
      @backtrace = backtrace
    end

    def log(level, heading = 3, msg)
      @heading_level = heading
      std_logger.send(level, msg)
    end

    def inspect_backtrace(ignore = 3)
      return unless backtrace
      lines =
        case backtrace
        when true then caller(ignore)
        when Regexp then caller(ignore).grep(backtrace)
        else
          []
        end
      lines.map { |l| "* #{l.chop}`" }.join("\n")
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
        "#{'#' * heading_level} #{severity} in #{Process.pid} at #{time.iso8601} -- #{msg}\n\n"
      end
    end
  end
end
