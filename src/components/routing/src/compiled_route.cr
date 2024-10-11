# Represents an immutable snapshot of an `ART::Route` that exposes the `Regex` patterns and variables used to match/generate the route.
struct Athena::Routing::CompiledRoute
  # An immutable representation of a segment of a route used to reconstruct a valid URL from an `ART::CompiledRoute`.
  struct Token
    # Represents if a `ART::CompiledRoute::Token` is static text, or has a variable portion.
    enum Type
      # Static text.
      TEXT

      # Variable data.
      VARIABLE
    end

    # Returns the type this token represents.
    getter type : Type

    # Returns that static prefix related to this token.
    getter prefix : String

    # Returns the pattern this `ART::CompiledRoute::Token::Type::VARIABLE` token requires.
    getter regex : Regex?

    # Returns the name of parameter this `ART::CompiledRoute::Token::Type::VARIABLE` token represents.
    getter var_name : String?

    # Returns `true` if this token should always be included within the generated URL, otherwise `false`.
    getter? important : Bool

    def initialize(
      @type : Type,
      @prefix : String,
      @regex : Regex? = nil,
      @var_name : String? = nil,
      @important : Bool = false,
    )
    end

    # :nodoc:
    def_clone
  end

  # Returns the static text prefix of this route.
  getter static_prefix : String

  # Returns the regex pattern used to match this route.
  getter regex : Regex

  # Returns the tokens that make up the path of this route.
  getter tokens : Array(ART::CompiledRoute::Token)

  # Returns the names of the route parameters within this route.
  getter path_variables : Set(String)

  # Returns the regex pattern used to match the hostname of this route.
  getter host_regex : Regex?

  # Returns the tokens that make up the hostname of this route.
  getter host_tokens : Array(ART::CompiledRoute::Token)

  # Returns the names of the route parameters within the hostname pattern this route.
  getter host_variables : Set(String)

  # Returns the compiled parameter names from the path and hostname patterns.
  getter variables : Set(String)

  def initialize(
    @static_prefix : String,
    @regex : Regex,
    @tokens : Array(ART::CompiledRoute::Token),
    @path_variables : Set(String),
    @host_regex : Regex? = nil,
    @host_tokens : Array(ART::CompiledRoute::Token) = Array(ART::CompiledRoute::Token).new,
    @host_variables : Set(String) = Set(String).new,
    @variables : Set(String) = Set(String).new,
  )
  end

  # :nodoc:
  def_clone
end
