@[ADI::Register(alias: Athena::Framework::ErrorRendererInterface)]
# The default `ATH::ErrorRendererInterface`, JSON serializes the exception.
struct Athena::Framework::ErrorRenderer
  include Athena::Framework::ErrorRendererInterface

  # :inherit:
  def render(exception : ::Exception) : ATH::Response
    if exception.is_a? ATH::Exceptions::HTTPException
      status = exception.status
      headers = exception.headers
    else
      status = HTTP::Status::INTERNAL_SERVER_ERROR
      headers = HTTP::Headers.new
    end

    headers["content-type"] = "application/json; charset=UTF-8"

    ATH::Response.new exception.to_json, status, headers
  end
end
