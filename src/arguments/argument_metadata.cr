abstract struct Athena::Routing::Arguments::Argument; end

struct Athena::Routing::Arguments::ArgumentMetadata(T) < Athena::Routing::Arguments::Argument
  # The name of the parameter.
  getter name : String

  # The value to use if it was not provided
  getter default : T?

  # The type of the parameter, i.e. what the type restriction in the action is.
  getter type : T.class

  # If this argument has a default value.
  getter? has_default : Bool

  # If `nil` is a valid argument for the argument.
  getter? nillable : Bool

  def initialize(@name : String, is_nillable : Bool = false, @default : T? = nil, @type : T.class = T)
    @has_default = !@default.nil?
    @nillable = is_nillable || @type == Nil || (@has_default && @default.nil?)
  end
end
