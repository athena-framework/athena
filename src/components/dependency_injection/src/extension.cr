module Athena::DependencyInjection::Extension
  macro included
    # :nodoc:
    OPTIONS = [] of Nil

    private def initialize; end
  end

  macro property(decl)
    {% OPTIONS << decl %}

    #
    #
    # Default value of: '{{decl.type}}'
    abstract def {{decl.var.id}} : {{decl.type.id}}
  end
end
