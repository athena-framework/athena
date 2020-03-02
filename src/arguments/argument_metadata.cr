# Parent type of an argument's metadata just used for typing.
#
# See `ART::Arguments::ArgumentMetadata`.
#
# TODO: Remove the fake method signatures once [this issue](https://github.com/crystal-lang/crystal/issues/6996) is resolved.
abstract struct Athena::Routing::Arguments::ArgumentMetadataBase
  def has_default?
    false
  end

  def nillable?
    false
  end

  def type
    Int32
  end

  def name
    ""
  end

  def default; end
end

# Represents a controller action argument.  Stores metadata associated with it, such as its name, type, and default value if any.
struct Athena::Routing::Arguments::ArgumentMetadata(T) < Athena::Routing::Arguments::ArgumentMetadataBase
  # The name of the argument.
  getter name : String

  # The default value of an argument.
  #
  # See `ART::Arguments::Resolvers::DefaultValue`.
  getter default : T?

  # The type of the parameter, i.e. what its type restriction is.
  getter type : T.class

  # If this argument has a default value.
  getter? has_default : Bool

  # If `nil` is a valid argument for the argument.
  getter? nillable : Bool

  def initialize(@name : String, @has_default : Bool, is_nillable : Bool = false, @default : T? = nil, @type : T.class = T)
    @nillable = is_nillable || @type == Nil || (@has_default && @default.nil?)
  end
end
