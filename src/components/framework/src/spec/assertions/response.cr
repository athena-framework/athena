require "spec"

# :nodoc:
struct ResponseIsSuccessful
  def match(actual_value : HTTP::Server::Response) : Bool
    actual_value.status.success?
  end

  def match(actual_value : _) : Bool
    false
  end

  def failure_message(actual_value)
    String.build do |io|
      io << "Failed asserting that the response is successful:\n#{actual_value}"

      if (exception_message = actual_value.headers["x-debug-exception"]?.presence) && (exception_file = actual_value.headers["x-debug-exception-file"]?.presence)
        file, line, column = exception_file.split ':'
        io << '\n' << '\n'

        io << "Caused By:\n  '" << URI.decode(exception_message) << "' at " << exception_file
      end
    end
  end

  def negative_failure_message(actual_value)
    "Failed asserting that the response is not successful:\n#{actual_value}"
  end
end

module Athena::Framework::Spec::Assertions::Response
  def assert_response_is_successful(failure_message : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__)
    self.assert_with_response ResponseIsSuccessful.new, failure_message, file, line
  end

  def assert_with_response(
    expectation,
    failure_message : String?,
    file : String,
    line : Int32
  ) : Nil
    response = self.response

    response.should expectation, file: file, line: line
  end

  private abstract def client : AbstractBrowser?

  private def response : HTTP::Server::Response
    self.client.response
  end
end
