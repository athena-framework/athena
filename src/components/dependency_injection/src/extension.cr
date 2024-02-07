module Athena::DependencyInjection::Extension::Schema
  macro included
    # :nodoc:
    OPTIONS = [] of Nil
  end

  macro property(decl)
    {% OPTIONS << decl %}
    {%
      default_string = if !(v = decl.value).is_a? Nop
                         "Default value of `#{v}`."
                       else
                         ""
                       end
    %}

    # {{ @caller.first.doc_comment }}
    #
    # {{default_string.id}}
    abstract def {{decl.var.id}} : {{decl.type.id}}
  end
end
