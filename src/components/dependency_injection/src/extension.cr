module Athena::DependencyInjection::Extension::Schema
  macro included
    # :nodoc:
    OPTIONS = [] of Nil
  end

  macro property(declaration)
    {%
      __nil = nil

      # Special case: Allow using NoReturn to "inherit" type from the TypeDeclaration for Array types.
      # I.e. to make it so you do not have to retype the type if its long/complex
      default = if declaration.type.resolve <= Array &&
                   !declaration.value.is_a?(Nop) &&
                   (array_type = ((declaration.value.of || declaration.value.type))) &&
                   !array_type.is_a?(Nop) &&
                   array_type.resolve == NoReturn.resolve
                  "#{declaration.type.id}.new".id
                else
                  declaration.value
                end

      OPTIONS << {name: declaration.var.id, type: declaration.type.resolve, default: default, root: declaration}
    %}
  end

  macro object_of(name, *members)
    process_object_of({{name}}, {{members.splat}}, nilable: false)
  end

  macro object_of?(name, *members)
    process_object_of({{name}}, {{members.splat}}, nilable: true)
  end

  private macro process_object_of(name_or_assign, *members, nilable)
    {%
      __nil = nil

      if name_or_assign.is_a?(Assign)
        name = name_or_assign.target
        default = name_or_assign.value
      else
        name = name_or_assign.name
        default = pp # Hack to ensure the default is a Nop to differentiate it from `nil`
      end

      member_map = {__nil: nil}
      members.each do |m|
        m.raise "All members must be `TypeDeclaration`s." unless m.is_a? TypeDeclaration
        member_map[m.var.id] = m
      end

      OPTIONS << {name: name, type: (type = (nilable ? parse_type("NamedTuple?").resolve : NamedTuple)), default: default, root: name, members: member_map}
    %}
  end

  # An array of a complex type
  macro array_of(name, *members)
    process_array_of({{name}}, {{members.splat}}, nilable: false)
  end

  macro array_of?(name, *members)
    process_array_of({{name}}, {{members.splat}}, nilable: true)
  end

  private macro process_array_of(name_or_assign, *members, nilable)
    {%
      __nil = nil

      if name_or_assign.is_a?(Assign)
        name = name_or_assign.target.id
        default = name_or_assign.value
      else
        name = name_or_assign.name
        default = [] of NoReturn
      end

      member_map = {__nil: nil}
      members.each do |m|
        m.raise "All members must be `TypeDeclaration`s." unless m.is_a? TypeDeclaration
        member_map[m.var.id] = m
      end

      OPTIONS << {name: name, type: (type = (nilable ? parse_type("Array?").resolve : Array)), default: nilable ? nil : default, root: name, members: member_map}
    %}
  end
end
