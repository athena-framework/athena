# Used to denote a module as an extension schema.
# Defines the configuration properties exposed to compile passes added via `ADI.add_compiler_pass`.
# Schemas must be registered via `ADI.register_extension`.
#
# EXPERIMENTAL: This feature is intended for internal/advanced use and, for now, comes with limited public documentation.
#
# ## Member Markup
#
# `#object_of` and `#array_of` support a special doc comment markup that can be used to better document each member of the objects.
# The markup consists of `---` to denote the start and end of the block.
# `>>` denotes the start of the docs for a specific property.
# The name of the property followed by a `:` should directly follow.
# From there, any text will be attributed to that property, until the next `>>` or `---`.
# Not all properties need to be included.
#
# For example:
#
# ```
# module Schema
#   include ADI::Extension::Schema
#
#   # Represents a connection to the database.
#   #
#   # ---
#   # >>username: The username, should be set to `admin` for elevated privileges.
#   # >>port: Defaults to the default PG port.
#   # ---
#   object_of? connection, username : String, password : String, port : Int32 = 5432
# end
# ```
#
# WARNING: The custom markup is only supported when using `mkdocs` with some custom templates.
module Athena::DependencyInjection::Extension::Schema
  macro included
    # :nodoc:
    OPTIONS = [] of Nil

    # This must be public so its included in docs and mkdocs can access it.
    CONFIG_DOCS = [] of Nil
  end

  # Defines a schema property via the provided [declaration](https://crystal-lang.org/api/Crystal/Macros/TypeDeclaration.html).
  # The type may be any primitive Crystal type (String, Bool, Array, Hash, Enum, Number, etc).
  #
  # ```
  # module Schema
  #   include ADI::Extension::Schema
  #
  #   property enabled : Bool = true
  #   property name : String
  # end
  #
  # ADI.register_extension "test", Schema
  #
  # ADI.configure({
  #   test: {
  #     name: "Fred",
  #   },
  # })
  # ```
  macro property(declaration)
    {%
      __nil = nil

      # Special case: Allow using NoReturn to "inherit" type from the TypeDeclaration for Array types.
      # I.e. to make it so you do not have to retype the type if its long/complex
      default = if declaration.type.resolve <= Array &&
                   !declaration.value.is_a?(Nop) &&
                   declaration.value.is_a?(ArrayLiteral) &&
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

  # Defines a required strictly typed `NamedTupleLiteral` object with the provided *name* and *members*.
  # The members consist of a variadic list of [declarations](https://crystal-lang.org/api/Crystal/Macros/TypeDeclaration.html), with optional default values.
  # ```
  # module Schema
  #   include ADI::Extension::Schema
  #
  #   object_of connection,
  #     username : String,
  #     password : String,
  #     hostname : String = "localhost",
  #     port : Int32 = 5432
  # end
  #
  # ADI.register_extension "test", Schema
  #
  # ADI.configure({
  #   test: {
  #     connection: {username: "admin", password: "abc123"},
  #   },
  # })
  # ```
  #
  # This macro is preferred over a direct `NamedTuple` type as it allows default values to be defined, and for the members to be documented via the special [Member Markup][Athena::DependencyInjection::Extension::Schema--member-markup]
  macro object_of(name, *members)
    process_object_of({{name}}, {{members.splat}}, nilable: false)
  end

  # Same as `#object_of` but makes the object optional, defaulting to `nil`.
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
        members_string += %({"name":"#{m.var.id}","type":"`#{m.type.id}`","default":"`#{m.value.id}`","doc":"#{(member_doc_map[m.var.stringify] || "").strip.strip.gsub(/"/, "\\\"").id}"})
        members_string += "," unless idx == members.size - 1
      end
      members_string += "]"

      OPTIONS << {name: name, type: (type = (nilable ? parse_type("NamedTuple?").resolve : NamedTuple)), default: nilable ? nil : default, root: name, members: member_map}
      CONFIG_DOCS << %({"name":"#{name.id}","type":"`#{type.id}`","default":"`#{(nilable && default.is_a?(Nop) ? nil : default).id}`","members":#{members_string.id}}).id
    %}

    # {{ doc_string.strip.id }}
    abstract def {{name.id}}
  end

  # Similar to `#object_of`, but defines an array of objects.
  # ```
  # module Schema
  #   include ADI::Extension::Schema
  #
  #   array_of rules,
  #     path : String,
  #     value : String
  # end
  #
  # ADI.register_extension "test", Schema
  #
  # ADI.configure({
  #   test: {
  #     rules: [
  #       {path: "/foo", value: "foo"},
  #       {path: "/bar", value: "bar"},
  #     ],
  #   },
  # })
  # ```
  #
  # If not provided, the property defaults to an empty array.
  macro array_of(name, *members)
    process_array_of({{name}}, {{members.splat}}, nilable: false)
  end

  # Same as `#array_of` but makes the default value of the property `nil`.
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
        members_string += %({"name":"#{m.var.id}","type":"`#{m.type.id}`","default":"`#{m.value.id}`","doc":"#{(member_doc_map[m.var.stringify] || "").strip.strip.gsub(/"/, "\\\"").id}"})
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
