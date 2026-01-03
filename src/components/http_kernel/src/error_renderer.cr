# The default `AHK::ErrorRendererInterface`, JSON serializes the exception.
struct Athena::HTTPKernel::ErrorRenderer
  include Athena::HTTPKernel::ErrorRendererInterface

  def initialize(@debug : Bool); end

  # :inherit:
  def render(exception : ::Exception) : AHTTP::Response
    headers = ::HTTP::Headers.new
    content = exception.to_json

    if exception.is_a? AHK::Exception::HTTPException
      status = exception.status
      headers = exception.headers
    elsif exception.is_a?(AHTTP::Exception::RequestExceptionInterface)
      status = ::HTTP::Status::BAD_REQUEST
      content = {code: 400, message: "Bad Request"}.to_json
    else
      status = ::HTTP::Status::INTERNAL_SERVER_ERROR
    end

    headers["content-type"] = "application/json; charset=utf-8"

    # TODO: Use a better API to get the file/line/column info.
    if @debug && (backtrace = exception.backtrace?.try(&.first).to_s.presence)
      if (match = backtrace.match(/(.*):(\d+):(\d+)/)) || (match = backtrace.match(/(.*):(\d+)/))
        headers["x-debug-exception-message"] = URI.encode_path exception.message.to_s
        headers["x-debug-exception-class"] = exception.class.to_s
        headers["x-debug-exception-code"] = status.value.to_s

        file = "#{URI.encode_path(match[1])}:#{match[2]}"

        if m3 = match[3]?
          file = "#{file}:#{m3}"
        end

        headers["x-debug-exception-file"] = file
      end
    end

    AHTTP::Response.new content, status, headers
  end
end
