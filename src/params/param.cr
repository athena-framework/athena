require "./param_interface"

abstract struct Athena::Routing::Params::Param(T)
  include Athena::Routing::Params::ParamInterface(T)

  # :inherit:
  getter name : String

  getter default : T?

  getter incompatibilities : Array(String) = [] of String

  getter? strict : Bool = true

  # The type of the parameter, i.e. what its type restriction is.
  getter type : T.class

  # If this argument has a default value.
  getter? has_default : Bool

  @nilable : Bool

  # If `nil` is a valid value for the param.
  getter? nilable : Bool

  def initialize(
    @name : String,
    @has_default : Bool,
    @incompatibilities : Array(String) = [] of String,
    is_nilable : Bool = false,
    @strict : Bool = true,
    @key : String? = nil,
    @default : T? = nil,
    @type : T.class = T
  )
    @nilable = is_nilable || @type == Nil || (@has_default && @default.nil?)
  end

  def constraints : Array(AVD::Constraint)
    constraints = [] of AVD::Constraint

    unless self.nilable?
      constraints << AVD::Constraints::NotNil.new
    end

    constraints
  end

  def key : String
    @key || @name
  end
end
