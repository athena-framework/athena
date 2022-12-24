# :nodoc:
struct Athena::Framework::Spec::Expectations::Response::HasHeader < Athena::Framework::Spec::Expectations::Response::Base
  @name : String

  def initialize(
    @name : String,

    description : String? = nil
  )
    super description
  end

  def match(actual_value : ::HTTP::Server::Response) : Bool
    actual_value.headers.has_key? @name
  end

  private def failure_message : String
    "has header '#{@name}'"
  end

  private def negated_failure_message : String
    "does not have header '#{@name}'"
  end

  private def include_response? : Bool
    false
  end
end
