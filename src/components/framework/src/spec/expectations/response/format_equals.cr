# :nodoc:
struct Athena::Framework::Spec::Expectations::Response::FormatEquals < Athena::Framework::Spec::Expectations::Response::Base
  @request : ATH::Request
  @format : String?

  def initialize(
    @request : ATH::Request,
    @format : String? = nil,
    description : String? = nil
  )
    super description
  end

  def match(actual_value : ::HTTP::Server::Response) : Bool
    return false unless (content_type = actual_value.headers["content-type"]?)

    @format == @request.format(content_type)
  end

  private def failure_message : String
    "format is '#{@format || "null"}'"
  end

  private def negated_failure_message : String
    "format is not '#{@format || "null"}'"
  end
end
