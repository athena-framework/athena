# Raised when a `.env` file is unable to be read, or non-existent.
class Athena::Dotenv::Exceptions::Path < RuntimeError
  def initialize(path : String | Path, cause : ::Exception? = nil)
    super "Unable to read the '#{path}' environment file.", cause
  end
end
