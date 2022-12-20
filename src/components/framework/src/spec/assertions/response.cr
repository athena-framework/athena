require "spec"

module Athena::Framework::Spec::Assertions::Response
  def assert_response_is_successful(failure_message : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__)
    self.assert_with_response do |response|
      message = String.build do |io|
        io << "Failed asserting the response is successful:"
        io << '\n' << '\n'
        io << response.version << ' ' << response.status_code << ' ' << response.status.description << '\n' << '\n'
        HTTP.serialize_headers_and_string_body io, response.headers, response.body
      end

      fail "#{failure_message}\n#{message}", file: file, line: line unless response.status.success?
    end
  end

  def assert_with_response(& : HTTP::Server::Response ->) : Nil
    yield self.response
  rescue ex : ::Spec::AssertionFailed
    raise ::Spec::AssertionFailed.new ex.message, ArgumentError.new("testing")
    raise ex
  end

  private abstract def client : AbstractBrowser?

  private def response : HTTP::Server::Response
    client = self.client

    client.response
  end
end
