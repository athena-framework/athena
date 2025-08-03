# Allows prompting the user to confirm an action.
#
# ```
# question = ACON::Question::Confirmation.new "Continue with this action?", false
# helper = self.helper ACON::Helper::Question
#
# if !helper.ask input, output, question
#   return ACON::Command::Status::SUCCESS
# end
#
# # ...
# ```
#
# In this example the user will be asked if they wish to `Continue with this action`.
# The `#ask` method will return `true` if the user enters anything starting with `y`, otherwise `false`.
class Athena::Console::Question::Confirmation < Athena::Console::Question(Bool)
  @true_answer_regex : Regex

  # Creates a new instance of self with the provided *question* string.
  # The *default* parameter represents the value to return if no valid input was entered.
  # The *true_answer_regex* can be used to customize the pattern used to determine if the user's input evaluates to `true`.
  def initialize(question : String, default : Bool = true, @true_answer_regex : Regex = /^y/i)
    super question, default

    self.normalizer = ->default_normalizer(String | Bool)
  end

  private def default_normalizer(answer : String | Bool) : Bool
    if answer.is_a? Bool
      return answer
    end

    answer_is_true = answer.matches? @true_answer_regex

    if false == @default
      return !answer.blank? && answer_is_true
    end

    answer.empty? || answer_is_true
  end
end
