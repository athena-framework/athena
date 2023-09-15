# :nodoc:
struct Athena::Console::Completion::Output::Zsh < Athena::Console::Completion::Output::Interface
  # :nodoc:
  record Script, command_name : String, version : Int32 do
    ECR.def_to_s "#{__DIR__}/completion.zsh"
  end

  def write(suggestions : ACON::Completion::Suggestions, output : ACON::Output::Interface) : Nil
    values = suggestions.suggested_values.map do |v|
      "#{v.value}#{(desc = v.description.presence) ? "\t#{desc}" : ""}"
    end

    suggestions.suggested_options.each do |option|
      values << "--#{option.name}#{(desc = option.description.presence) ? "\t#{desc}" : ""}"

      if option.negatable?
        values << "--no-#{option.name}#{(desc = option.description.presence) ? "\t#{desc}" : ""}"
      end
    end

    output.puts values.join "\n"
  end
end
