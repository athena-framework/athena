# :nodoc:
struct Athena::Framework::Spec::Expectations::Response::IsRedirected < Athena::Framework::Spec::Expectations::Response::Base
  def match(actual_value : ::HTTP::Server::Response) : Bool
    actual_value.status.redirection?
  end

  private def failure_message : String
    "is redirected"
  end

  private def negated_failure_message : String
    "is not redirected"
  end
end
