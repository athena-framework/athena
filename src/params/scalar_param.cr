abstract struct Athena::Routing::Params::ScalarParam < Athena::Routing::Params::Param
  getter requirements : AVD::Constraint | Array(AVD::Constraint) | Regex | Nil

  getter? map : Bool = false

  def initialize(
    name : String,
    has_default : Bool = false,
    incompatibilities : Array(String)? = nil,
    @requirements : AVD::Constraint | Array(AVD::Constraint) | Regex | Nil = nil,
    @map : Bool = false,
    strict : Bool = true,
    nilable : Bool = false,
    key : String? = nil,
    description : String? = nil
  )
    super name, has_default, incompatibilities, strict, nilable, key, description
  end

  # :inherit:
  def constraints : Array(AVD::Constraint)
    constraints = super

    case (requirements = @requirements)
    when Array(AVD::Constraint) then constraints.concat requirements
    when AVD::Constraint        then constraints << requirements
    when Regex                  then constraints << AVD::Constraints::Regex.new requirements, message: "Parameter '#{@name}' value does not match requirements '{{ pattern }}'"
    end

    if @map
      constraints = [AVD::Constraints::All.new(constraints)] of AVD::Constraint

      unless self.nilable?
        constraints << AVD::Constraints::NotNil.new
      end
    end

    constraints
  end

  # Used in QueryParam and RequestParam to reduce duplication when defining default and type getters.
  private macro define_initializer
    getter default : T?

    # The type of the parameter, i.e. what its type restriction is.
    getter type : T.class

    def initialize(
      name : String,
      has_default : Bool = false,
      incompatibilities : Array(String)? = nil,
      requirements : AVD::Constraint | Array(AVD::Constraint) | Regex | Nil = nil,
      map : Bool = false,
      is_nilable : Bool = false,
      strict : Bool = true,
      key : String? = nil,
      description : String? = nil,
      @default : T? = nil,
      @type : T.class = T,
      converter : Nil? = nil # TODO: Remove this
    )
      super name, has_default, incompatibilities, requirements, map, strict, (is_nilable || @type == Nil || (has_default && @default.nil?)), key, description
    end
  end
end
