require "./abstract_choice"

# A question whose answer _MUST_ be within a set of predefined answers.
# If the user enters an invalid answer, an error is displayed and they are prompted again.
#
# ```
# question = ACON::Question::Choice.new "What is your favorite color?", {"red", "blue", "green"}
#
# helper = self.helper ACON::Helper::Question
# color = helper.ask input, output, question
# ```
#
# This would display something like the following:
#
# ```sh
# What is your favorite color?
#  [0] red
#  [1] blue
#  [2] green
# >
# ```
#
# The user would be able to enter the name of the color, or the index associated with it. E.g. `blue` or `2` for `green`.
# If a `Hash` is used as the choices, the key of each choice is used instead of its index.
#
# Similar to `ACON::Question`, the third argument can be set to set the default choice.
# This value can also either be the actual value, or the index/key of the related choice.
#
# ```
# question = ACON::Question::Choice.new "What is your favorite color?", {"c1" => "red", "c2" => "blue", "c3" => "green"}, "c2"
#
# helper = self.helper ACON::Helper::Question
# color = helper.ask input, output, question
# ```
#
# Which would display something like :
#
# ```sh
# What is your favorite color?
#  [c1] red
#  [c2] blue
#  [c3] green
# >
# ```
class Athena::Console::Question::Choice(T) < Athena::Console::Question::AbstractChoice(T, T?)
  protected def default_validator(answer : T?) : T?
    self.selected_choices(answer).first?
  end

  protected def parse_answers(answer : T?) : Array(String)
    [answer || ""]
  end
end
