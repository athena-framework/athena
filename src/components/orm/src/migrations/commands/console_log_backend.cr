# :nodoc:
#
# Writes the entries logged to `AORM::Migrations::Log` while a migrations command runs to its output, errors to the error output when there is one.
class Athena::ORM::Migrations::Commands::ConsoleLogBackend < ::Log::Backend
  # Returns the lowest severity written for *verbosity*: notices by default, info with `-v`, and debug with `-vv`.
  def self.severity(verbosity : ACON::Output::Verbosity) : ::Log::Severity
    case verbosity
    when .quiet?, .silent? then ::Log::Severity::None
    when .normal?          then ::Log::Severity::Notice
    when .verbose?         then ::Log::Severity::Info
    else                        ::Log::Severity::Debug
    end
  end

  def initialize(@output : ACON::Output::Interface)
    super :direct
  end

  def write(entry : ::Log::Entry) : Nil
    output = @output

    return if entry.severity < self.class.severity(output.verbosity)

    error = entry.severity >= ::Log::Severity::Error
    style = error ? "error" : "info"
    level = entry.severity.warn? ? "warning" : entry.severity.label.downcase

    output = output.error_output if error && output.is_a?(ACON::Output::ConsoleOutputInterface)

    output.puts "<#{style}>[#{level}] #{ACON::Formatter::Output.escape entry.message}</#{style}>"
  end
end
