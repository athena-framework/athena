require "./abstract_choice"

# Similar to `ACON::Question::Choice`, but allows for more than one answer to be selected.
# This question accepts a comma separated list of answers.
#
# ```
# question = ACON::Question::MultipleChoice.new "What is your favorite color?", {"red", "blue", "green"}
# answer = helper.ask input, output, question
# ```
#
# This question is also similar to `ACON::Question::Choice` in that you can provide either the index, key, or value of the choice.
# For example submitting `green,0` would result in `["green", "red"]` as the value of `answer`.
class Athena::Console::Question::MultipleChoice(T) < Athena::Console::Question::AbstractChoice(T, Array(T))
  protected def default_validator(answer : T?) : Array(T)
    self.selected_choices answer
  end

  protected def parse_answers(answer : T?) : Array(String)
    answer.try(&.split(',')) || [""]
  end
end
