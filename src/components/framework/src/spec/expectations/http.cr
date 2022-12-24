require "./response/*"
require "./request/*"

module Athena::Framework::Spec::Expectations::HTTP
  def assert_response_is_successful(description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should Response::IsSuccessful.new(description), file: file, line: line
  end

  def assert_response_is_unprocessable(description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should Response::IsUnprocessable.new(description), file: file, line: line
  end

  def assert_response_has_status(status : ::HTTP::Status | Int32, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should Response::HasStatus.new(status.is_a?(Int32) ? ::HTTP::Status.from_value(status) : status, description), file: file, line: line
  end

  def assert_response_has_header(name : String, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should Response::HasHeader.new(name, description), file: file, line: line
  end

  def assert_response_not_has_header(name : String, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should_not Response::HasHeader.new(name, description), file: file, line: line
  end

  def assert_response_has_cookie(name : String, path : String? = nil, domain : String? = nil, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should Response::HasCookie.new(name, path, domain, description), file: file, line: line
  end

  def assert_response_not_has_cookie(name : String, path : String? = nil, domain : String? = nil, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should_not Response::HasCookie.new(name, path, domain, description), file: file, line: line
  end

  def assert_response_format_equals(format : String, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should Response::FormatEquals.new(self.request, format, description), file: file, line: line
  end

  def assert_response_header_equals(name : String, value : String, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should Response::HeaderEquals.new(name, value, description), file: file, line: line
  end

  def assert_response_header_not_equals(name : String, value : String, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should_not Response::HeaderEquals.new(name, value, description), file: file, line: line
  end

  def assert_cookie_has_value(name : String, value : String, path : String? = nil, domain : String? = nil, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should Response::HasCookie.new(name, path, domain, description), file: file, line: line
    self.response.should Response::CookieValueEquals.new(name, value, path, domain, description), file: file, line: line
  end

  def assert_request_attribute_equals(name : String, value : _, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.request.should Request::AttributeEquals.new(name, value, description), file: file, line: line
  end

  def assert_route_equals(name : String, parameters : Hash? = nil, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.request.should Request::AttributeEquals.new("_route", name, description), file: file, line: line

    parameters.try &.each do |k, v|
      self.request.should Request::AttributeEquals.new(k, v, description), file: file, line: line
    end
  end

  def assert_response_redirects(location : String? = nil, status : ::HTTP::Status | Int32 | Nil = nil, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should Response::IsRedirected.new(description), file: file, line: line
    self.response.should Response::HeaderEquals.new("location", location), file: file, line: line if location
    self.response.should Response::HasStatus.new(status), file: file, line: line if status
  end

  private abstract def client : AbstractBrowser?

  private def response : ::HTTP::Server::Response
    self.client.response
  end

  private def request : ATH::Request
    self.client.request
  end
end
