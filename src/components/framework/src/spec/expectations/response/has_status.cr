# :nodoc:
struct Athena::Framework::Spec::Expectations::Response::HasStatus < Athena::Framework::Spec::Expectations::Response::Base
  @status : ::HTTP::Status

  def self.new(
    status_code : Int32,
    description : String? = nil
  )
    new ::HTTP::Status.from_value(status_code), description
  end

  def initialize(
    @status : ::HTTP::Status,
    description : String? = nil
  )
    super description
  end

  def match(actual_value : ::HTTP::Server::Response) : Bool
    actual_value.status == @status
  end

  private def failure_message : String
    "status is '#{@status}'"
  end

  private def negated_failure_message : String
    "status is not '#{@status}'"
  end
end
