@[ADI::Register(alias: Athena::Routing::ErrorRendererInterface)]
# The default `ART::ErrorRendererInterface`, JSON serializes the exception.
struct Athena::Routing::ErrorRenderer
  include Athena::Routing::ErrorRendererInterface

  # :inherit:
  def render(exception : ::Exception) : ART::Response
    if exception.is_a? ART::Exceptions::HTTPException
      status = exception.status
      headers = exception.headers
    else
      status = HTTP::Status::INTERNAL_SERVER_ERROR
      headers = HTTP::Headers.new
    end

    headers["content-type"] = "application/json; charset=UTF-8"

    ART::Response.new exception.to_json, status, headers
  end
end
