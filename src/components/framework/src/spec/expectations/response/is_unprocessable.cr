# :nodoc:
struct Athena::Framework::Spec::Expectations::Response::IsUnprocessable < Athena::Framework::Spec::Expectations::Response::Base
  def match(actual_value : ::HTTP::Server::Response) : Bool
    actual_value.status.unprocessable_entity?
  end

  private def failure_message : String
    "is unprocessable"
  end

  private def negated_failure_message : String
    "is not unprocessable"
  end
end
