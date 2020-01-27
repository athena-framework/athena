@[Athena::DI::Register]
struct Athena::Routing::ErrorRenderer
  include Athena::Routing::ErrorRendererInterface
  include ADI::Service

  def render(exception : ::Exception) : ART::Response
    status = HTTP::Status::INTERNAL_SERVER_ERROR

    if exception.is_a? ART::Exceptions::HTTPException
      status = exception.status
      headers = exception.headers
    end

    ART::Response.new exception.to_json, status, headers || HTTP::Headers.new
  end
end
