# An `ATH::View` represents an `ATH::Response`, but in a format agnostic way.
#
# Returning a `ATH::View` is essentially the same as returning the data directly; but allows customizing
# the response status and headers without needing to render the response body within the controller as an `ATH::Response`.
#
# ```
# require "athena"
#
# class HelloController < ATH::Controller
#   @[ARTA::Get("/{name}")]
#   def say_hello(name : String) : NamedTuple(greeting: String)
#     {greeting: "Hello #{name}"}
#   end
#
#   @[ARTA::Get("/view/{name}")]
#   def say_hello_view(name : String) : ATH::View(NamedTuple(greeting: String))
#     self.view({greeting: "Hello #{name}"}, :im_a_teapot)
#   end
# end
#
# ATH.run
#
# # GET /Fred      # => 200 {"greeting":"Hello Fred"}
# # GET /view/Fred # => 418 {"greeting":"Hello Fred"}
# ```
#
# See the [negotiation](/components/negotiation) component for more information.
class Athena::Framework::View(T)
  # The response data.
  property data : T

  # The `HTTP::Status` of the underlying `#response`.
  property status : HTTP::Status?

  # The format the view should be rendered in.
  #
  # The *format* must be registered with the `ATH::Request::FORMATS` hash;
  # either as a built in format, or a custom one that has registered via `ATH::Request.register_format`.
  property format : String? = nil

  # The parameters that should be used when constructing the redirect `#route` URL.
  property route_params : Hash(String, String?) = Hash(String, String?).new

  property context : ATH::View::Context { ATH::View::Context.new }

  # Returns the `URL` that the current request should be redirected to.
  #
  # See the [Location](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Location) header documentation.
  getter location : String? = nil

  # Returns the name of the route the current request should be redirected to.
  #
  # See the [URL Generation](/getting_started/#url-generation) documentation.
  getter route : String? = nil

  # The wrapped `ATH::Response` instance.
  property response : ATH::Response do
    response = ATH::Response.new

    if status = @status
      response.status = status
    end

    response
  end

  # Creates a view instance that'll redirect to the provided *url*. See `#location`.
  #
  # Optionally allows setting the underlying *status* and/or *headers*.
  def self.create_redirect(
    url : String,
    status : HTTP::Status = HTTP::Status::FOUND,
    headers : HTTP::Headers = HTTP::Headers.new
  ) : self
    view = ATH::View(Nil).new status: status, headers: headers
    view.location = url

    view
  end

  # Creates a view instance that'll redirect to the provided *route*. See `#route`.
  #
  # Optionally allows setting the underlying route *params*, *status*, and/or *headers*.
  def self.create_route_redirect(
    route : String,
    params : Hash(String, _) = Hash(String, String?).new,
    status : HTTP::Status = HTTP::Status::FOUND,
    headers : HTTP::Headers = HTTP::Headers.new
  ) : self
    view = ATH::View(Nil).new status: status, headers: headers
    view.route = route
    view.route_params = params.transform_values &.to_s.as(String?)

    view
  end

  def initialize(@data : T? = nil, @status : HTTP::Status? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    self.headers = headers unless headers.empty?
  end

  # Returns the headers of the underlying `#response`.
  def headers : ATH::Response::Headers
    self.response.headers
  end

  # Sets the redirect `#location`.
  def location=(@location : String) : Nil
    @route = nil
  end

  # Returns the type of the data represented by `self`.
  def return_type : T.class
    T
  end

  # Sets the redirect `#route`.
  def route=(@route : String) : Nil
    @location = nil
  end

  # Adds the provided header *name* and *value* to the underlying `#response`.
  def set_header(name : String, value : String) : Nil
    self.response.headers[name] = value
  end

  # :ditto:
  def set_header(name : String, value : _) : Nil
    self.set_header name, value.to_s
  end

  # Sets the *headers* that should be returned as part of the underlying `#response`.
  def headers=(headers : HTTP::Headers) : Nil
    self.response.headers.clear
    self.response.headers.merge! headers
  end

  # Does type reduction logic to determine what serializer the data should use.
  # `nil` for `ASR::Serializable`, otherwise `JSON::Serializable`.
  protected def serializable_data : T?
    {% if (T <= JSON::Serializable) && !(T <= ASR::Serializable) %}
      # Single JSON::Serializable object
      self.data
    {% elsif (T <= Enumerable) && T.type_vars.any? { |t| (t <= JSON::Serializable) && !(t <= ASR::Serializable) } %}
      # Array of JSON::Serializable
      self.data
    {% else %}
      nil
    {% end %}
  end
end
