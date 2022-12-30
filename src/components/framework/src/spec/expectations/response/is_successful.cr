# :nodoc:
struct Athena::Framework::Spec::Expectations::Response::IsSuccessful < Athena::Framework::Spec::Expectations::Response::Base
  def match(actual_value : ::HTTP::Server::Response) : Bool
    actual_value.status.success?
  end

  private def failure_message : String
    "is successful"
  end

  private def negated_failure_message : String
    "is not successful"
  end
end
