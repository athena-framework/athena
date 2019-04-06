module Athena::Cli
  # Parent struct for all CLI commands.
  abstract struct Command
    # Name of the command.
    class_property name : String = ""

    # What the command does.
    class_property description : String = ""

    macro inherited
      macro finished
        \{% begin %}
          \{% raise "#{@type.name} must implement a `self.execute` method." unless @type.class.methods.any? { |m| m.name.stringify == "execute"} %}
          \{% for method in @type.class.methods %}
            \{% if method.name.stringify == "execute" %}

              def self.to_s : String
                String.build do |str|
                  str.puts "Command"
                  str.puts "\t#{@@name} - #{@@description}"
                  str.puts "Usage"
                  str.puts "\t./YOUR_BINARY -c #{@@name} [arguments]"
                  str.puts "Arguments"
                  \{% for arg in method.args %}
                    str.puts "\t--#{\{{arg.name.stringify}}} : #{\{{arg.restriction}}}#{\{{arg.default_value.is_a?(Nop) ? "" : " = " + arg.default_value.stringify}}}"
                  \{% end %}
                end
              end

              # Executer for the command `MyClass.command.call(args : Array(String))`.
              class_getter command : Proc(Array(String), \{{method.return_type}}) = ->(args : Array(String)) do
              \{% arg_types = method.args.map(&.restriction) %}
                params = Array(Union(\{{arg_types.splat}}) | Nil).new

                \{% for arg in method.args %}
                  if arg = args.find { |a| a =~ /--\{{arg.name}}[=\s].+/ }
                    if val = arg.match /--\{{arg.name}}[=\s](.+)/
                      params << Athena::Types.convert_type val[1], \{{arg.restriction}}
                    end
                  else
                    \{% if arg.default_value.is_a? Nop %}
                       raise "Required argument '#{\{{arg.name.stringify}}}' was not supplied." unless (\{{arg.restriction}}).nilable?
                       params << nil
                    \{% else %}
                      params << \{{arg.default_value}}
                    \{% end %}
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
