module Athena::Routing::Exceptions
  COMMON_EXCEPTIONS = {
    401 => "Unauthorized",
    402 => "Payment Required",
    403 => "Forbidden",
    404 => "Not Found",
    405 => "Method Not Allowed",
    406 => "Not Acceptable",
    407 => "Proxy Authentication Required",
    408 => "Request Timeout",
    409 => "Conflict",
    410 => "Gone",
    411 => "Length Required",
    412 => "Precondition Failed",
    413 => "Payload Too Large",
    414 => "URI Too Long",
    415 => "Unsupported Media Type",
    416 => "Range Not Satisfiable",
    417 => "Expectation Failed",
    418 => "I'm A Teapot",
    421 => "Misdirected Request",
    422 => "Unprocessable Entity",
    423 => "Locked",
    424 => "Failed Dependency",
    426 => "Upgrade Required",
    428 => "Precondition Required",
    429 => "Too Many Requests",
    431 => "Request Header Fields Too Large",
    451 => "Unavailable For Legal Reasons",
  }

  # A generic exception that can be thrown with to render consistent exception responses with the given *code* and *message*.
  class AthenaException < Exception
    getter code : Int32

    def initialize(@code : Int32, @message); end

    # Serializes the exception into a JSON object with the given *code* and *message*.
    #
    # ```
    # {
    #   "code":    409,
    #   "message": "A user with this email already exists.",
    # }
    # ```
    def to_json : String
      {
        code:    @code,
        message: @message,
      }.to_json
    end
  end

  {% begin %}
    {% for code, exception in COMMON_EXCEPTIONS %}
      {% class_name = exception.gsub(/[\s\']/, "") %}

      # Raises a {{exception}} exception with code {{code}}
      class {{class_name.id}}Exception < Athena::Routing::Exceptions::AthenaException
        def initialize(message : String = {{exception}})
          super {{code.id}}, message
        end
      end
    {% end %}
  {% end %}
end
