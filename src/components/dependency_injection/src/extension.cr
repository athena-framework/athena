module Athena::DependencyInjection::Extension::Schema
  macro included
    # :nodoc:
    OPTIONS = [] of Nil
  end

  # bool foo          - non-nilable required
  # bool foo = false  - non-nilable optional
  # bool? foo         - nilable required
  # bool? foo = false - nilable required

  macro bool(assign_or_var)
    add_config_property({{assign_or_var}}, Bool)
  end

  macro bool?(assign_or_var)
    add_config_property({{assign_or_var}}, Bool?)
  end

  macro string(assign_or_var)
    add_config_property({{assign_or_var}}, String)
  end

  macro string?(assign_or_var)
    add_config_property({{assign_or_var}}, String?)
  end

  macro int(assign_or_var, size = Int32)
    add_config_property({{assign_or_var}}, {{size}})
  end

  macro int?(assign_or_var, size = Int32?)
    add_config_property({{assign_or_var}}, {{size}}?)
  end

  macro bigint(assign_or_var)
    int({{assign_or_var}}, Int64)
  end

  macro bigint?(assign_or_var)
    int({{assign_or_var}}, Int64?)
  end

  macro float(assign_or_var, size = Float64)
    add_config_property({{assign_or_var}}, {{size}})
  end

  macro float?(assign_or_var, size = Float64?)
    add_config_property({{assign_or_var}}, {{size}}?)
  end

  private macro add_config_property(assign_or_var, type)
    {%
      if assign_or_var.is_a?(Assign)
        name = assign_or_var.target.id
        default = assign_or_var.value
      else
        name = assign_or_var.id
        default = pp # Hack to ensure the default is a Nop to differentiate it from `nil`
      end
    %}

    {%
      declaration = {name: name, type: type.resolve, default: default, root: assign_or_var}

      OPTIONS << declaration
    %}
  end

  macro array(declaration)
    process_array({{declaration}}, false)
  end

  macro array?(declaration)
    process_array({{declaration}}, true)
  end

  private macro process_array(declaration, nilable)
    {%
      __nil = nil

      type_string = if nilable
                      "Array(#{declaration.type})?"
                    else
                      "Array(#{declaration.type})"
                    end

      # Special case: Allow using NoReturn to "inherit" type from the TypeDeclaration.
      # I.e. to make it so you do not have to retype the type if its long/complex
      default = if (!declaration.value.is_a?(Nop) &&
                   (array_type = ((declaration.value.of || declaration.value.type))) &&
                   !array_type.is_a?(Nop) &&
                   array_type.resolve == NoReturn.resolve)
                  "#{type_string.id}.new".id
                else
                  declaration.value
                end

      OPTIONS << {name: declaration.var.id, type: parse_type(type_string).resolve, default: default, root: declaration, members: [] of Nil}
    %}
  end

  # An array of a complex type
  macro array_of(name, *members)
    process_array_of({{name}}, {{members.splat}}, nilable: false)
  end

  macro array_of?(name, *members)
    process_array_of({{name}}, {{members.splat}}, nilable: true)
  end

  private macro process_array_of(name, *members, nilable)
    {%
      members.each do |m|
        m.raise "All members must be `TypeDeclaration`s." unless m.is_a? TypeDeclaration
      end

      OPTIONS << {name: name.id, type: nilable ? Array? : Array, default: default, root: name, members: members}
    %}
  end

  macro type_of(declaration)
    {% OPTIONS << {name: declaration.var.id, type: declaration.type.resolve, default: declaration.value, root: declaration} %}
  end
end
