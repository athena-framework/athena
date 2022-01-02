# Represents a controller action argument. Stores metadata associated with it, such as its name, type, and default value if any.
struct Athena::Framework::Arguments::ArgumentMetadata(T)
  # The name of the argument.
  getter name : String

  # The type of the parameter, i.e. what its type restriction is.
  getter type : T.class

  # If `nil` is a valid argument for the argument.
  getter? nilable : Bool

  def initialize(@name : String, is_nilable : Bool = false, @type : T.class = T)
    @nilable = is_nilable || @type == Nil
  end
end
