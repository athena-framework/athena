module Athena::DependencyInjection::Extension::Schema
  macro included
    # :nodoc:
    OPTIONS = [] of Nil

    # This must be public so its included in docs and mkdocs can access it.
    CONFIG_DOCS = [] of Nil
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
      CONFIG_DOCS << %({"name":"#{declaration.var.id}","type":"`#{declaration.type.id}`","default":"`#{default.id}`"}).id
    %}

    # {{ @caller.first.doc_comment }}
    abstract def {{declaration.var.id}} : {{declaration.type.id}}
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
        name = name_or_assign.target.id
        default = name_or_assign.value
      else
        name = name_or_assign.name
        default = pp # Hack to ensure the default is a Nop to differentiate it from `nil`
      end

      doc_string = ""
      member_doc_map = {} of Nil => Nil
      in_member_docblock = false
      current_member = nil

      @caller.first.doc.lines.each_with_index do |line, idx|
        # --- denotes member docblock start/end
        if "---" == line
          in_member_docblock = true

          # >> denotes start of property docs
        elsif in_member_docblock && line.starts_with?(">>")
          current_member, docs = line[2..].split(':')

          member_doc_map[current_member.id.stringify] = "#{docs.id}\\n"
        elsif current_member
          member_doc_map[current_member.id.stringify] += "#{line.id}\\n"
        elsif "---" == line && in_member_docblock
          in_member_docblock = false
          current_member = nil
        else
          # The line where the docs are added in already have a `#`,
          # so no need to
          doc_string += "#{idx == 0 ? "".id : "\# ".id}#{line.id}\n"
        end
      end

      members_string = "["
      member_map = {__nil: nil}
      members.each_with_index do |m, idx|
        m.raise "All members must be `TypeDeclaration`s." unless m.is_a? TypeDeclaration
        member_map[m.var.id] = m
        members_string += %({"name":"#{m.var.id}","type":"`#{m.type.id}`","default":"`#{m.value.id}`","doc":"#{(member_doc_map[m.var.stringify] || "NONE").strip.strip.gsub(/"/, "\\\"").id}"})
        members_string += "," unless idx == members.size - 1
      end
      members_string += "]"

      OPTIONS << {name: name, type: (type = (nilable ? parse_type("NamedTuple?").resolve : NamedTuple)), default: nilable ? nil : default, root: name, members: member_map}
      CONFIG_DOCS << %({"name":"#{name.id}","type":"`#{type.id}`","default":"`#{(nilable && default.is_a?(Nop) ? nil : default).id}`","members":#{members_string.id}}).id
    %}

    # {{ doc_string.strip.id }}
    abstract def {{name.id}}
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

      doc_string = ""
      member_doc_map = {} of Nil => Nil
      in_member_docblock = false
      current_member = nil

      @caller.first.doc.lines.each_with_index do |line, idx|
        # --- denotes member docblock start/end
        if "---" == line
          in_member_docblock = true

          # >> denotes start of property docs
        elsif in_member_docblock && line.starts_with?(">>")
          current_member, docs = line[2..].split(':')

          member_doc_map[current_member.id.stringify] = "#{docs.id}\\n"
        elsif current_member
          member_doc_map[current_member.id.stringify] += "#{line.id}\\n"
        elsif "---" == line && in_member_docblock
          in_member_docblock = false
          current_member = nil
        else
          # The line where the docs are added in already have a `#`,
          # so no need to
          doc_string += "#{idx == 0 ? "".id : "\# ".id}#{line.id}\n"
        end
      end

      members_string = "["
      member_map = {__nil: nil}
      members.each_with_index do |m, idx|
        m.raise "All members must be `TypeDeclaration`s." unless m.is_a? TypeDeclaration
        member_map[m.var.id] = m
        members_string += %({"name":"#{m.var.id}","type":"`#{m.type.id}`","default":"`#{m.value.id}`","doc":"#{(member_doc_map[m.var.stringify] || "NONE").strip.strip.gsub(/"/, "\\\"").id}"})
        members_string += "," unless idx == members.size - 1
      end
      members_string += "]"

      OPTIONS << {name: name, type: (type = (nilable ? parse_type("Array?").resolve : Array)), default: nilable ? nil : default, root: name, members: member_map}
      CONFIG_DOCS << %({"name":"#{name.id}","type":"`#{type.id}`","default":"`#{(nilable && default.empty? ? nil : default).id}`","members":#{members_string.id}}).id
    %}

    # {{ doc_string.strip.id }}
    abstract def {{name.id}}
  end
end
