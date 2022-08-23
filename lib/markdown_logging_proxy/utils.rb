module MarkdownLoggingProxy
  module Utils
    def self.heading_level
      @heading_level || 1
    end

    def self.heading_level=(level)
      @heading_level = level
    end

    def self.create_logger(location)
      logger = location.kind_of?(Logger) ? location : Logger.new(location)
      format_logger logger
    end

    def self.format_logger(logger)
      logger.formatter = proc do |severity, time, _, msg|
        "#{'#' * heading_level} #{severity} in #{Process.pid} at #{time.iso8601} -- #{msg}\n\n"
      end
      logger
    end
  end
end