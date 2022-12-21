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

    # TODO: Use a better API to get the line and column.
    if match = exception.backtrace?.try(&.first).to_s.match(/(.*):(\d+):(\d+)/)
      headers["x-debug-exception"] = URI.encode_path exception.message.to_s
      headers["x-debug-exception-file"] = "#{URI.encode_path(match[1])}:#{match[2]}:#{match[3]}"
    end

    ATH::Response.new exception.to_json, status, headers
  end
end
