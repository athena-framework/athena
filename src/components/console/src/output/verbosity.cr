# Verbosity levels determine which messages will be displayed, essentially the same idea as [Log::Severity](https://crystal-lang.org/api/Log/Severity.html) but for console output.
#
# For example:
#
# ```sh
# # Output nothing
# ./console my-command --silent
#
# # Output only errors
# ./console my-command -q
# ./console my-command --quiet
#
# # Display only useful output
# ./console my-command
#
# # Increase the verbosity of messages
# ./console my-command -v
#
# # Also display non-essential information
# ./console my-command -vv
#
# # Display all messages, such as for debugging
# ./console my-command -vvv
# ```
#
# As used in the previous example, the verbosity can be controlled on a command invocation basis using a CLI option,
# but may also be globally set via the `SHELL_VERBOSITY` environmental variable.
#
# When you output a message via `ACON::Output::Interface#puts` or `ACON::Output::Interface#print`, they also provide a way to set the verbosity at which that message should print:
#
# ```
# protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
#   # Via conditional logic
#   if output.verbosity.verbose?
#     output.puts "Obj class: #{obj.class}"
#   end
#
#   # Inline within the method
#   output.puts "Only print this in verbose mode or higher", verbosity: :verbose
#
#   ACON::Command::Status::SUCCESS
# end
# ```
#
# TIP: The full stack trace of an exception is printed in `ACON::Output::Verbosity::VERBOSE` mode or higher.
enum Athena::Console::Output::Verbosity
  # Silences all output.
  # Equivalent to `--silent` CLI option or `SHELL_VERBOSITY=-2`.
  SILENT = -2

  # Output only errors.
  # Equivalent to `-q`, `--quiet` CLI options or `SHELL_VERBOSITY=-1`.
  QUIET = -1

  # Normal behavior, display only useful messages.
  # Equivalent not providing any CLI options or `SHELL_VERBOSITY=0`.
  NORMAL = 0

  # Increase the verbosity of messages.
  # Equivalent to `-v`, `--verbose=1` CLI options or `SHELL_VERBOSITY=1`.
  VERBOSE = 1

  # Display all the informative non-essential messages.
  # Equivalent to `-vv`, `--verbose=2` CLI options or `SHELL_VERBOSITY=2`.
  VERY_VERBOSE = 2

  # Display all messages, such as for debugging.
  # Equivalent to `-vvv`, `--verbose=3` CLI options or `SHELL_VERBOSITY=3`.
  DEBUG = 3
end
