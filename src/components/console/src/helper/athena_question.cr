abstract class Athena::Console::Helper; end

require "./question"

# Extension of `ACON::Helper::Question` that provides more structured output.
#
# See `ACON::Style::Athena`.
class Athena::Console::Helper::AthenaQuestion < Athena::Console::Helper::Question
  protected def write_error(output : ACON::Output::Interface, error : Exception) : Nil
    if output.is_a? ACON::Style::Athena
      output.new_line
      output.error error.message || ""

      return
    end

    super
  end

  # ameba:disable Metrics/CyclomaticComplexity
  protected def write_prompt(output : ACON::Output::Interface, question : ACON::Question::Base) : Nil
    text = ACON::Formatter::Output.escape_trailing_backslash question.question
    default = question.default

    if question.multi_line?
      text = "#{text} (press #{self.eof_shortcut} to continue)"
    end

    text = if default.nil?
             " <info>#{text}</info>:"
           elsif question.is_a? ACON::Question::Confirmation
             %( <info>#{text} (yes/no)</info> [<comment>#{default ? "yes" : "no"}</comment>]:)
           elsif question.is_a? ACON::Question::MultipleChoice
             choices = question.choices
             default = case default
                       when String then default.split(',').map! do |item|
                         if idx = item.to_i?
                           item = idx
                         end

                         choices[item]? || item.to_s
                       end
                       else
                         [default]
                       end

             %( <info>#{text}</info> [<comment>#{ACON::Formatter::Output.escape default.join(", ")}</comment>]:)
           elsif question.is_a? ACON::Question::Choice
             choices = question.choices

             " <info>#{text}</info> [<comment>#{ACON::Formatter::Output.escape default.to_s}</comment>]:"
           else
             " <info>#{text}</info> [<comment>#{ACON::Formatter::Output.escape default.to_s}</comment>]:"
           end

    output.puts text

    prompt = " > "

    if question.is_a? ACON::Question::AbstractChoice
      output.puts self.format_choice_question_choices question, "comment"

      prompt = question.prompt
    end

    output.print prompt
  end

  private def eof_shortcut : String
    # TODO: Windows uses Ctrl+Z + Enter

    "<comment>Ctrl+D</comment>"
  end
end
