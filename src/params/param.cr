require "./param_interface"

abstract struct Athena::Routing::Params::Param
  include Athena::Routing::Params::ParamInterface

  # :inherit:
  getter name : String
  getter description : String?

  getter incompatibilities : Array(String)?

  getter? strict : Bool = true

  # If this argument has a default value.
  getter? has_default : Bool

  # If `nil` is a valid value for the param.
  getter? nilable : Bool

  def initialize(
    @name : String,
    @has_default : Bool = false,
    @incompatibilities : Array(String)? = nil,
    @strict : Bool = true,
    @nilable : Bool = false,
    @key : String? = nil,
    @description : String? = nil
  )
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
