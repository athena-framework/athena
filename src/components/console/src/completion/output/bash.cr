struct Athena::Console::Completion::Output::Bash < Athena::Console::Completion::OutputInterface
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
