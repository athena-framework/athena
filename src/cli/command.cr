module Athena::Cli
  # Parent struct for all CLI commands.
  abstract struct Command
    # Name of the command.
    class_property command_name : String = ""

    # Description of what the command does
    class_property description : String = ""

    macro inherited
      macro finished
        \{% begin %}
          \{% for method in @type.class.methods %}
            \{% if method.name.stringify == "execute" %}
              # Arguments that the command takes.  Automatically generated based on the names/types of the `self.execute` method.  Nilable parameters are considered optional to the command.
              class_property arguments = [\{{method.args.map { |a| "Athena::Cli::Argument(#{a.restriction}).new(#{a.name.stringify}, #{a.restriction.is_a?(Path) ? a.restriction.resolve.nilable? : a.restriction.types.any? { |t| t.resolve.nilable? } })".id }.splat}}]
            \{% end %}
          \{% end %}
        \{% end %}
      end
    end

    # :nodoc:
    def self.run(args : Array(String), command : Athena::Cli::Command.class) : Nil
      {% begin %}
        {% for m in @type.class.methods %}
          {% if m.name.stringify == "execute" %}
            {% arg_types = m.args.map(&.restriction) %}
              params = Array(Union({{arg_types.splat}}) | Nil).new
              arguments.each do |argument|
                if arg = args.find { |arg| arg =~ /--#{argument.name}=.+/ }
                  if val = arg.match /--#{argument.name}=(.+)/
                    params << Athena::Types.convert_type val[1], argument.type
                  end
                else
                  raise "Required argument '#{argument.name}' was not supplied." unless argument.optional
                  params << nil
                end
              end
              command.execute *Tuple({{arg_types.splat}}).from params
          {% end %}
        {% end %}
      {% end %}
    end
  end
end
