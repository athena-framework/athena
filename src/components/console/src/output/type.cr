# Determines how a message should be printed.
#
# When you output a message via `ACON::Output::Interface#puts` or `ACON::Output::Interface#print`, they also provide a way to set the output type it should be printed:
#
# ```
# protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
#   output.puts "Some Message", output_type: :raw
#
#   ACON::Command::Status::SUCCESS
# end
# ```
enum Athena::Console::Output::Type
  # Normal output, with any styles applied to format the text.
  NORMAL

  # Output style tags as is without formatting the string.
  RAW

  # Strip any style tags and only output the actual text.
  PLAIN
end
