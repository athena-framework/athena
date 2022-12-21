struct Athena::Framework::Spec::Expectations::Response::HeaderEquals < Athena::Framework::Spec::Expectations::Response::Base
  @header_name : String
  @value : String

  def initialize(
    @header_name : String,
    @value : String,
    description : String? = nil
  )
    super description
  end

  def match(actual_value : HTTP::Server::Response) : Bool
    @value == actual_value.headers[@header_name]?
  end

  private def failure_message : String
    "has header '#{@header_name}' with value '#{@value}'"
  end

  private def negated_failure_message : String
    "does not have header '#{@header_name}' with value '#{@value}'"
  end
end
