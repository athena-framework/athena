# Represents a controller action argument.  Stores metadata associated with it, such as its name, type, and default value if any.
struct Athena::Framework::Arguments::ArgumentMetadata(T)
  # The name of the argument.
  getter name : String

  # The default value of the argument, if any.
  #
  # See `ATH::Arguments::Resolvers::DefaultValue`.
  getter default : T?

  # The type of the parameter, i.e. what its type restriction is.
  getter type : T.class

  # If this argument has a default value.
  getter? has_default : Bool

  # If `nil` is a valid argument for the argument.
  getter? nilable : Bool

  def initialize(@name : String, @has_default : Bool, is_nilable : Bool = false, @default : T? = nil, @type : T.class = T)
    @nilable = is_nilable || @type == Nil || (@has_default && @default.nil?)
  end
end
