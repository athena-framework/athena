require "./base"

# This namespaces contains various questions that can be asked via the `ACON::Helper::Question` helper or `ART::Style::Athena` style.
#
# This class can also be used to ask the user for more information in the most basic form, a simple question and answer.
#
# ## Usage
#
# ```
# question = ACON::Question(String?).new "What is your name?", nil
# name = helper.ask input, output, question
# ```
#
# This will prompt to user to enter their name. If they do not enter valid input, the default value of `nil` will be used.
# The default can be customized, ideally with sane defaults to make the UX better.
#
# ### Trimming the Answer
#
# By default the answer is [trimmed](https://crystal-lang.org/api/String.html#strip%3AString-instance-method) in order to remove leading and trailing white space.
# The `ACON::Question::Base#trimmable=` method can be used to disable this if you need the input as is.
#
# ```
# question = ACON::Question(String?).new "What is your name?", nil
# question.trimmable = false
# name_with_whitespace_and_newline = helper.ask input, output, question
# ```
#
# ### Multiline Input
#
# The question helper will stop reading input when it receives a newline character. I.e. the user presses the `ENTER` key.
# However in some cases you may want to allow for an answer that spans multiple lines.
# The `ACON::Question::Base#multi_line=` method can be used to enable multi line mode.
#
# ```
# question = ACON::Question(String?).new "Tell me a story.", nil
# question.multi_line = true
# ```
#
# Multiline questions stop reading user input after receiving an end-of-transmission control character. (`Ctrl+D` on Unix systems).
#
# ### Hiding User Input
#
# If your question is asking for sensitive information, such as a password, you can set a question to hidden.
# This will make it so the input string is not displayed on the terminal, which is equivalent to how password are handled on Unix systems.
#
# ```
# question = ACON::Question(String?).new "What is your password?.", nil
# question.hidden = true
# ```
#
# WARNING: If no method to hide the response is available on the underlying system/input, it will fallback and allow the response to be seen.
# If having the hidden response hidden is vital, you _MUST_ set `ACON::Question::Base#hidden_fallback=` to `false`; which will
# raise an exception instead of allowing the input to be visible.
#
# ### Normalizing the Answer
#
# The answer can be "normalized" before being validated to fix any small errors or tweak it as needed.
# For example, you could normalize the casing of the input:
#
# ```
# question = ACON::Question(String?).new "Enter your name.", nil
# question.normalizer do |input|
#   input.try &.downcase
# end
# ```
#
# It is possible for *input* to be `nil` in this case, so that need to also be handled in the block.
# The block should return a value of the same type of the generic, in this case `String?`.
#
# NOTE: The normalizer is called first and its return value is used as the input of the validator.
# If the answer is invalid do not raise an exception in the normalizer and let the validator handle it.
#
# ### Validating the Answer
#
# If the answer to a question needs to match some specific requirements, you can register a question validator to check the validity of the answer.
# This callback should raise an exception if the input is not valid, such as `ArgumentError`. Otherwise, it must return the input value.
#
# ```
# question = ACON::Question(String?).new "Enter your name.", nil
# question.validator do |input|
#   next input if input.nil? || !input.starts_with? /^\d+/
#
#   raise ArgumentError.new "Invalid name. Cannot start with numeric digits."
# end
# ```
#
# In this example, we are asserting that the user's name does not start with numeric digits.
# If the user entered `123Jim`, they would be told it is an invalid answer and prompted to answer the question again.
# By default the user would have an unlimited amount of retries to get it right, but this can be customized via `ACON::Question::Base#max_attempts=`.
#
# ### Autocompletion
#
# TODO: Implement this.
class Athena::Console::Question(T)
  include Athena::Console::Question::Base(T)

  # See [Validating the Answer][Athena::Console::Question--validating-the-answer].
  property validator : Proc(T, T)? = nil

  # Sets the validator callback to this block.
  # See [Validating the Answer][Athena::Console::Question--validating-the-answer].
  def validator(&@validator : T -> T) : Nil
  end
end
