require "crylog"

module Athena
  # Default directory where the logs are stored.
  LOGS_DIR = "logs"

  # Returns a logger with the given *channel*.
  def self.logger(channel : String = Crylog.default_channel) : Crylog::Logger
    Crylog.logger channel
  end

  # Default logger configuration.
  #
  # Override this method to define a custom logger configuration.
  protected def self.configure_logger : Nil
    # Create the logs dir if it doesn't exist already.
    Dir.mkdir LOGS_DIR unless Dir.exists? LOGS_DIR
    Crylog.configure do |registry|
      registry.register "main" do |logger|
        handlers = [] of Crylog::Handlers::LogHandler

        if Athena.config.environment == "development"
          # Log to STDOUT and development log file if in develop env
          handlers << Crylog::Handlers::IOHandler.new(STDOUT)
          handlers << Crylog::Handlers::IOHandler.new(File.open("#{LOGS_DIR}/development.log", "a"))
        elsif Athena.config.environment == "production"
          # Log warnings and higher to production log file if in production env.
          handlers << Crylog::Handlers::IOHandler.new(File.open("#{LOGS_DIR}/production.log", "a"), severity: Crylog::Severity::Warning)
        end

        logger.handlers = handlers
      end
    end
  end
end
