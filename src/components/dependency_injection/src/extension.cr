module Athena::DependencyInjection::Extension
  macro included
    OPTIONS = [] of Nil

    private def initialize; end
  end

  macro option(decl)
    {% OPTIONS << decl %}
  end
end
