abstract struct Athena::Routing::Params::ScalarParam(T) < Athena::Routing::Params::Param(T)
  getter requirements : AVD::Constraint | Array(AVD::Constraint) | Regex | Nil

  getter? map : Bool = false

  def initialize(
    name : String,
    has_default : Bool = false,
    incompatibilities : Array(String) = [] of String,
    @requirements : AVD::Constraint | Array(AVD::Constraint) | Regex | Nil = nil,
    @map : Bool = false,
    is_nilable : Bool = false,
    strict : Bool = true,
    key : String? = nil,
    default : T? = nil,
    type : T.class = T,
    converter : Nil? = nil # TODO: Remove this
  )
    super name, has_default, incompatibilities, is_nilable, strict, key, default, type
  end

  def constraints : Array(AVD::Constraint)
    constraints = super

    case (requirements = @requirements)
    when Array(AVD::Constraint) then constraints.concat requirements
    when AVD::Constraint        then constraints << requirements
    when Regex                  then constraints << AVD::Constraints::Regex.new requirements, message: "Parameter '#{@name}' value does not match requirements '{{ pattern }}'"
    end

    if @map
      constraints = [AVD::Constraints::All.new(constraints)] of AVD::Constraint

      unless @nilable
        constraints << AVD::Constraints::NotNil.new
      end
    end

    constraints
  end
end
