module Athena::Cli
  # Parent struct for all CLI commands.
  abstract struct Command
    # Name of the command.
    class_property command_name : String = ""

    # Description of what the command does.
    class_property description : String = ""

    macro inherited
      macro finished
        \{% begin %}
          \{% for method in @type.class.methods %}
            \{% if method.name.stringify == "execute" %}
              # Arguments that the command takes.  Automatically generated based on the names/types of the `self.execute` method.  Nilable parameters are considered optional to the command.
              class_property arguments = [\{{method.args.map { |a| "Athena::Cli::Argument(#{a.restriction}).new(#{a.name.stringify}, #{a.restriction.is_a?(Path) ? a.restriction.resolve.nilable? : a.restriction.types.any? { |t| t.resolve.nilable? } })".id }.splat}}]

              # Executer for the command `MyClass.execute.call(args)`.
              class_getter execute : Proc(Array(String), \{{method.return_type}}) = ->(args : Array(String)) do
              \{% arg_types = method.args.map(&.restriction) %}
                params = Array(Union(\{{arg_types.splat}}) | Nil).new

                \{% for arg in method.args %}
                  if arg = args.find { |a| a =~ /--\{{arg.name}}=.+/ }
                    if val = arg.match /--\{{arg.name}}=(.+)/
                      params << Athena::Types.convert_type val[1], \{{arg.restriction}}
                    end
                  else
                    params << nil
                  end
               \{% end %}
                ->\{{@type}}.execute(\{{arg_types.splat}}).call *Tuple(\{{arg_types.splat}}).from params
               end
            \{% end %}
          \{% end %}
        \{% end %}
      end
    end
  end
end
