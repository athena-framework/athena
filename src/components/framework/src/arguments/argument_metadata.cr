# Represents a controller action argument. Stores metadata associated with it, such as its name, type, and default value if any.
struct Athena::Framework::Arguments::ArgumentMetadata(T)
  # The name of the argument.
  getter name : String

  def initialize(@name : String); end

  # If `nil` is a valid argument for the argument.
  def nilable? : Bool
    {{T.nilable?}}
  end

  # The type of the parameter, i.e. what its type restriction is.
  def type : T.class
    T
  end
end
