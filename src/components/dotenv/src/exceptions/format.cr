# Raised when there is a parsing error within a `.env` file.
class Athena::Dotenv::Exceptions::Format < RuntimeError
  # Stores contextual information related to an `Athena::Dotenv::Exceptions::Format`.
  #
  # ```
  # begin
  #   dotenv = Athena::Dotenv.new.parse "NAME=Jim\nFOO=BAR BAZ"
  # rescue ex : Athena::Dotenv::Exceptions::Format
  #   ctx = ex.context
  #
  #   ctx.path        # => ".env"
  #   ctx.line_number # => 2
  #   ctx.details     # => "...NAME=Jim\nFOO=BAR BAZ...\n                       ^ line 2 offset 20"
  # end
  # ```
  struct Context
    # Returns the path to the improperly formatted `.env` file.
    getter path : String

    # Returns the line number of the format error.
    getter line_number : Int32

    def initialize(
      @data : String,
      path : ::Path | String,
      @line_number : Int32,
      @offset : Int32
    )
      @path = path.to_s
    end

    # Returns a details string that includes the markup before/after the error, along with what line number and offset the error occurred at.
    def details : String
      before = @data[Math.max(0, @offset - 20), Math.min(20, @offset)].gsub "\n", "\\n"
      after = @data[@offset, 20].gsub "\n", "\\n"

      %(...#{before}#{after}...\n#{" " * (before.size + 2)}^ line #{@line_number} offset #{@offset})
    end
  end

  # Returns an object containing contextual information about this error.
  getter context : Athena::Dotenv::Exceptions::Format::Context

  def initialize(message : String, @context : Athena::Dotenv::Exceptions::Format::Context, cause : ::Exception? = nil)
    super "#{message} in '#{@context.path}' at line #{@context.line_number}.\n#{@context.details}", cause
  end
end
