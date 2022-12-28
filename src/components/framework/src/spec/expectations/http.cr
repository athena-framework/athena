require "./response/*"
require "./request/*"

# Provides expectation helper method for making assertions about the `ATH::Request` and/or `HTTP::Server::Response` of a controller action.
# For example asserting the response is successful, has a specific header/cookie (value), and/or if the request has an attribute with a specific value.
#
# ```
# struct ExampleControllerTest < ATH::Spec::APITestCase
#   def test_root : Nil
#     self.get "/"
#
#     self.assert_response_is_successful
#   end
# end
# ```
#
# Some expectations will also print more information upon failure to make it easier to understand _why_ it failed.
# `#assert_response_is_successful` for example will include the response status, headers, and body as well as the exception that caused the failure if applicable.
module Athena::Framework::Spec::Expectations::HTTP
  # Asserts the response returns with a [successful?](https://crystal-lang.org/api/HTTP/Status.html#success%3F%3ABool-instance-method) status code.
  def assert_response_is_successful(description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should Response::IsSuccessful.new(description), file: file, line: line
  end

  # Asserts the response returns with status of `422 Unprocessable Entity`.
  def assert_response_is_unprocessable(description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should Response::IsUnprocessable.new(description), file: file, line: line
  end

  # Asserts the response returns with a [redirection?](https://crystal-lang.org/api/HTTP/Status.html#redirection%3F%3ABool-instance-method) status code.
  # Optionally allows also asserting the `location` header is that of the provided *location*,
  # and/or the status is equal to the provided *status*.
  def assert_response_redirects(location : String? = nil, status : ::HTTP::Status | Int32 | Nil = nil, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should Response::IsRedirected.new(description), file: file, line: line
    self.response.should Response::HeaderEquals.new("location", location), file: file, line: line if location
    self.response.should Response::HasStatus.new(status), file: file, line: line if status
  end

  # Asserts the response has the same status as the one provided.
  def assert_response_has_status(status : ::HTTP::Status | Int32, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should Response::HasStatus.new(status.is_a?(Int32) ? ::HTTP::Status.from_value(status) : status, description), file: file, line: line
  end

  # Asserts the response has a header with the provided *name*.
  def assert_response_has_header(name : String, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should Response::HasHeader.new(name, description), file: file, line: line
  end

  # Asserts the response does not have a header with the provided *name*.
  def assert_response_not_has_header(name : String, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should_not Response::HasHeader.new(name, description), file: file, line: line
  end

  # Asserts the response has a cookie with the provided *name*, and optionally *path* and *domain*.
  def assert_response_has_cookie(name : String, path : String? = nil, domain : String? = nil, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should Response::HasCookie.new(name, path, domain, description), file: file, line: line
  end

  # Asserts the response does not have a cookie with the provided *name*, and optionally *path* and *domain*.
  def assert_response_not_has_cookie(name : String, path : String? = nil, domain : String? = nil, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should_not Response::HasCookie.new(name, path, domain, description), file: file, line: line
  end

  # Asserts the format of the response equals the provided *format*.
  def assert_response_format_equals(format : String, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should Response::FormatEquals.new(self.request, format, description), file: file, line: line
  end

  # Asserts the value of the header with the provided *name*, equals that of the provided *value*.
  def assert_response_header_equals(name : String, value : String, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should Response::HeaderEquals.new(name, value, description), file: file, line: line
  end

  # Asserts the value of the header with the provided *name*, does not equal that of the provided *value*.
  def assert_response_header_not_equals(name : String, value : String, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should_not Response::HeaderEquals.new(name, value, description), file: file, line: line
  end

  # Asserts the value of the cookie with the provided *name*, and optionally *path* and *domain*, equals that of the provided *value*
  def assert_cookie_has_value(name : String, value : String, path : String? = nil, domain : String? = nil, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.response.should Response::HasCookie.new(name, path, domain, description), file: file, line: line
    self.response.should Response::CookieValueEquals.new(name, value, path, domain, description), file: file, line: line
  end

  # Asserts the request attribute with the provided *name* equals the provided *value*.
  def assert_request_attribute_equals(name : String, value : _, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.request.should Request::AttributeEquals.new(name, value, description), file: file, line: line
  end

  # Asserts the request was matched against the route with the provided *name*.
  def assert_route_equals(name : String, parameters : Hash? = nil, description : String? = nil, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    self.request.should Request::AttributeEquals.new("_route", name, description), file: file, line: line

    parameters.try &.each do |k, v|
      self.request.should Request::AttributeEquals.new(k, v, description), file: file, line: line
    end
  end

  private abstract def client : AbstractBrowser?

  private def response : ::HTTP::Server::Response
    self.client.response
  end

  private def request : ATH::Request
    self.client.request
  end
end
