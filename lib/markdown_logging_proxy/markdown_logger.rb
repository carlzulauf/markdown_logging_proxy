module MarkdownLoggingProxy
  class MarkdownLogger
    def self.inspect_object(object, show_id = true)
      [
        '```ruby',
        ("# #{id_object(object)}" if show_id),
        object.pretty_inspect.chomp,
        '```'
      ].compact.join("\n")
    end

    def self.id_object(object)
      # #<Object:0x00007f5a0919e140>
      "`#<#{object.class}:0x#{object.object_id.to_s(16)}>`"
    end

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
