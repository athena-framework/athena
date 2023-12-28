module Athena::DependencyInjection::Extension::Schema
  macro included
    # :nodoc:
    OPTIONS = [] of Nil
  end

  macro property(decl)
    {% OPTIONS << decl %}

    #
    #
    # Default value of: '{{decl.type}}'
    abstract def {{decl.var.id}} : {{decl.type.id}}
  end

  # Alias to `.property` for handling Bool properties.
  macro property?(decl)
    property {{decl}}
  end
end
