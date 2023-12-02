# :nodoc:
struct Athena::Console::Spec::Expectations::CommandIsSuccessful
  def match(actual_value : ::ACON::Command::Status?) : Bool
    ACON::Command::Status::SUCCESS == actual_value
  end

  def failure_message(actual_value : ::ACON::Command::Status?) : String
    "The command was unsuccessful"
  end

  def negative_failure_message(actual_value : ::ACON::Command::Status?) : String
    "The command was unsuccessful"
  end
end
