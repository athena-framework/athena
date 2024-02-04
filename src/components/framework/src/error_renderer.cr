@[ADI::Register(_debug: "%framework.debug%", alias: Athena::Framework::ErrorRendererInterface)]
# The default `ATH::ErrorRendererInterface`, JSON serializes the exception.
struct Athena::Framework::ErrorRenderer
  include Athena::Framework::ErrorRendererInterface

  def initialize(@debug : Bool); end

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

    ATH::Response.new exception.to_json, status, headers
  end
end
