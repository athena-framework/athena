require "./response/*"

module Athena::Framework::Spec::Expectations::Response
  def assert_response_is_successful(description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.assert_for_response Response::IsSuccessful.new(description), file, line
  end

  def assert_response_has_status(status : HTTP::Status | Int32, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.assert_for_response Response::HasStatus.new(status.is_a?(Int32) ? HTTP::Status.from_value(status) : status, description), file, line
  end

  def assert_response_format_equals(format : String, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.assert_for_response Response::FormatEquals.new(self.request, format, description), file, line
  end

  def assert_response_redirects(location : String? = nil, status : HTTP::Status | Int32 | Nil = nil, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    expectations = [Response::IsRedirected.new description] of Response::Base

    expectations << Response::HeaderEquals.new "location", location if location
    expectations << Response::HasStatus.new status if status

    self.assert_for_response expectations, description
  end

  def assert_for_response(
    expectations : Array,
    file : String,
    line : Int32
  )
    expectations.each do |e|
      self.assert_for_response e, file, line
    end
  end

  def assert_for_response(
    expectation,
    file : String,
    line : Int32
  ) : Nil
    self.response.should expectation, file: file, line: line
  end

  private abstract def client : AbstractBrowser?

  private def response : HTTP::Server::Response
    self.client.response
  end

  private def request : ATH::Request
    self.client.request
  end
end
