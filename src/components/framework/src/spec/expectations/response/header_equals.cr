# :nodoc:
struct Athena::Framework::Spec::Expectations::Response::HeaderEquals < Athena::Framework::Spec::Expectations::Response::Base
  @name : String
  @value : String

  def initialize(
    @name : String,
    @value : String,
    description : String? = nil
  )
    super description
  end

  def match(actual_value : ::HTTP::Server::Response) : Bool
    @value == actual_value.headers[@name]?
  end

  private def failure_message : String
    "has header '#{@name}' with value '#{@value}'"
  end

  private def negated_failure_message : String
    "does not have header '#{@name}' with value '#{@value}'"
  end

  private def include_response? : Bool
    false
  end
end
