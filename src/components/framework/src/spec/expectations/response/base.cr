# :nodoc:
abstract struct Athena::Framework::Spec::Expectations::Response::Base
  @description : String?

  def initialize(@description : String? = nil); end

  abstract def match(actual_value : ::HTTP::Server::Response) : Bool
  abstract def failure_message : String
  abstract def negated_failure_message : String

  def match(actual_value : _) : Bool
    false
  end

  def failure_message(actual_value : ::HTTP::Server::Response) : String
    self.build_message actual_value, self.failure_message
  end

  def negative_failure_message(actual_value : ::HTTP::Server::Response) : String
    self.build_message actual_value, self.negated_failure_message
  end

  private def include_response? : Bool
    true
  end

  private def build_message(response : ::HTTP::Server::Response, message : String) : String
    String.build do |io|
      if desc = @description
        io << desc << '\n' << '\n'
      end

      io << "Failed asserting that the response #{message}#{self.include_response? ? ":\n#{response}" : "."}"

      if (
           ("500" == response.headers["x-debug-exception-code"]?.presence) &&
           (exception_message = response.headers["x-debug-exception-message"]?.presence) &&
           (exception_file = response.headers["x-debug-exception-file"]?.presence) &&
           (exception_class = response.headers["x-debug-exception-class"]?.presence)
         )
        io << '\n' << '\n'

        io << "Caused By:\n"
        io << ' ' << ' '
        URI.decode exception_message, io
        io << ' ' << '(' << exception_class << ')' << '\n'
        io << ' ' << ' ' << ' ' << ' ' << "from" << ' ' << exception_file
      end
    end
  end
end
