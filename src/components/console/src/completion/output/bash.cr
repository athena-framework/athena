require "./interface"

# :nodoc:
struct Athena::Console::Completion::Output::Bash < Athena::Console::Completion::Output::Interface
  # :nodoc:
  record Script, command_name : String, version : Int32 do
    ECR.def_to_s "#{__DIR__}/completion.bash"
  end

  def write(suggestions : ACON::Completion::Suggestions, output : ACON::Output::Interface) : Nil
    values = suggestions.suggested_values.map &.to_s

    suggestions.suggested_options.each do |option|
      values << "--#{option.name}"

      if option.negatable?
        values << "--no-#{option.name}"
      end
    end

    output.puts values.join "\n"
  end
end
