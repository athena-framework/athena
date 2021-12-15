# Represents a "style" that provides a way to abstract _how_ to format console input/output data
# such that you can reduce the amount of code needed, and to standardize the appearance.
#
# See `ACON::Style::Athena`.
#
# ## Custom Styles
#
# Custom styles can also be created by implementing this interface, and optionally extending from `ACON::Style::Output`
# which makes the style an `ACON::Output::Interface` as well as defining part of this interface.
# Then you could simply instantiate your custom style within a command as you would `ACON::Style::Athena`.
module Athena::Console::Style::Interface
  # Helper method for asking `ACON::Question` questions.
  abstract def ask(question : String, default : _)

  # Helper method for asking hidden `ACON::Question` questions.
  abstract def ask_hidden(question : String)

  # Formats and prints the provided *messages* within a caution block.
  abstract def caution(messages : String | Enumerable(String)) : Nil

  # Formats and prints the provided *messages* within a comment block.
  abstract def comment(messages : String | Enumerable(String)) : Nil

  # Helper method for asking `ACON::Question::Confirmation` questions.
  abstract def confirm(question : String, default : Bool = true) : Bool

  # Formats and prints the provided *messages* within a error block.
  abstract def error(messages : String | Enumerable(String)) : Nil

  # Helper method for asking `ACON::Question::Choice` questions.
  abstract def choice(question : String, choices : Indexable | Hash, default = nil)

  # Formats and prints the provided *messages* within a info block.
  abstract def info(messages : String | Enumerable(String)) : Nil

  # Formats and prints a bulleted list containing the provided *elements*.
  abstract def listing(elements : Enumerable) : Nil

  # Prints *count* empty new lines.
  abstract def new_line(count : Int32 = 1) : Nil

  # Formats and prints the provided *messages* within a note block.
  abstract def note(messages : String | Enumerable(String)) : Nil

  # Creates a section header with the provided *message*.
  abstract def section(message : String) : Nil

  # Formats and prints the provided *messages* within a success block.
  abstract def success(messages : String | Enumerable(String)) : Nil

  # Formats and prints the provided *messages* as text.
  abstract def text(messages : String | Enumerable(String)) : Nil

  # Formats and prints *message* as a title.
  abstract def title(message : String) : Nil

  # abstract def table(headers : Enumerable, rows : Enumerable(Enumerable)) : Nil
  # abstract def progress_start(max : Int32 = 0) : Nil
  # abstract def progress_advance(step : Int32 = 1) : Nil
  # abstract def progress_finish : Nil

  # Formats and prints the provided *messages* within a warning block.
  abstract def warning(messages : String | Enumerable(String)) : Nil
end
