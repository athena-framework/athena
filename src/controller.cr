# The core of any framework is routing; how a route is tied to an action.  Athena takes an annotation based approach; an annotation is applied to an instance method of a controller class,
# which will be executed when that endpoint receives a request.  The annotation includes the path as well as any constraints that a parameter must meet in order for the route to be invoked.
#
# Child controllers must inherit from `ART::Controller` (or an abstract child of it).  Each request gets its own instance of the controller to better allow for DI via `Athena::DI`.
#
# The return type of an action does _NOT_ have to be `String`.  Currently the response value is serialized by calling `.to_json` on the value.
# In the future a more flexible/proper view layer will be implemented.
#
# ### Example
# The following controller shows examples of the various routing features of Athena.  `ART::Controller` also defines various macro DSLs, such as `ART::Controller.get` to make defining routes
# seem more Sinatra/Kemal like.  See the documentation on the macros for more details.
#
# ```
# require "athena"
#
# # The `ART::Prefix` annotation can be applied to a controller to define a prefix to use for all routes within `self`.
# @[ART::Prefix("athena")]
# class TestController < ART::Controller
#   # A GET endpoint with no params returning a `String`.
#   #
#   # Action return type restrictions are required.
#   @[ART::Get(path: "/me")]
#   def get_me : String
#     "Jim"
#   end
#
#   # A GET endpoint with no params returning `Nil`.
#   # `Nil` return types are returned with a status
#   # of 204 no content
#   @[ART::Get(path: "/no_content")]
#   def get_no_content : Nil
#     # Do stuff
#   end
#
#   # A GET endpoint with two `Int32` params returning an `Int32`.
#   #
#   # The parameters of a route _MUST_ match the arguments of the action.
#   # Type restrictions on action arguments are required.
#   @[ART::Get(path: "/add/:val1/:val2")]
#   def add(val1 : Int32, val2 : Int32) : Int32
#     val1 + val2
#   end
#
#   # A GET endpoint with an `String` route param, and a required string query param that must match the given pattern; returning a `String`.
#   #
#   # A non-nilable type denotes it as required.  If the parameter is not supplied, and no default value is assigned, an `ART::Exceptions::BadRequest` exception is raised.
#   @[ART::QueryParam("time", constraints: /\d:\d:\d/)]
#   @[ART::Get(path: "/event/:event_name/")]
#   def event_time(event_name : String, time : String) : String
#     "#{event_name} occurred at #{time}"
#   end
#
#   # A GET endpoint with an optional query parameter and optional path param with a default value; returning a `NamedTuple(user_id : Int32?, page : Int32)`.
#   #
#   # A nilable type denotes it as optional.  If the parameter is not supplied (or could not be converted), and no default value is assigned, it is `nil`.
#   @[ART::QueryParam("user_id")]
#   @[ART::Get(path: "/events/(:page)")]
#   def events(user_id : Int32?, page : Int32 = 1) : NamedTuple(user_id: Int32?, page: Int32)
#     {user_id: user_id, page: page}
#   end
#
#   # A GET endpoint with param constraints.  The param must match the supplied Regex or it will not match and return a 404 error.
#   @[ART::Get(path: "/time/:time/", constraints: {"time" => /\d{2}:\d{2}:\d{2}/})]
#   def get_constraint(time : String) : String
#     time
#   end
#
#   # A POST endpoint with a route param and accessing the request body; returning a `Bool`.
#   #
#   # It is recommended to use param converters to pass an actual object representing the data (assuming the body is JSON)
#   # to the route's action; however the raw request body can be accessed by typing an action argument as `HTTP::Request`.
#   @[ART::Post(path: "/test/:expected")]
#   def post_body(expected : String, request : HTTP::Request) : Bool
#     expected == request.body.try &.gets_to_end
#   end
# end
#
# ART.run
#
# CLIENT = HTTP::Client.new "localhost", 3000
#
# CLIENT.get("/athena/me").body                      # => "Jim"
# CLIENT.get("/athena/add/50/25").body               # => 75
# CLIENT.get("/athena/event/foobar?time=1:1:1").body # => "foobar occurred at 1:1:1"
# CLIENT.get("/athena/events").body                  # => {"user_id":null,"page":1}
# CLIENT.get("/athena/events/17?user_id=19").body    # => {"user_id":19,"page":17}
# CLIENT.get("/athena/time/12:45:30").body           # => "12:45:30"
# CLIENT.get("/athena/time/12:aa:30").body           # => 404 not found
# CLIENT.get("/athena/no_content").body              # => 204 no content
# CLIENT.post("/athena/test/foo", body: "foo").body  # => true
# ```
abstract class Athena::Routing::Controller
  {% begin %}
    {% for method in ["GET", "POST", "PUT", "PATCH", "DELETE"] %}
      # Helper DSL macro for creating `{{method.id}}` actions.
      #
      # The first argument is the path that the action should handle; which maps to path on the HTTP method annotation.
      # The second argument is a variable amount of arguments with a syntax similar to Crystal's `record`.
      # There are also a few optional named arguments that map to the corresponding field on the HTTP method annotation.
      #
      # The macro simply defines a method based on the options passed to it.  Additional annotations, such as for query params
      # or a param converter can simply be added on top of the macro.
      #
      # ### Optional Named Arguments
      # - `return_type` - The return type to set for the action.  Defaults to `String` if not provided.
      # - `constraints` - Any constraints that should be applied to the route.
      #
      # ### Example
      #
      # ```
      # class ExampleController < ART::Controller
      #   {{method.downcase.id}} "values/:value1/:value2", value1: Int32, value2 : Float64, constraints: {"value1" => /\d+/, "value2" => /\d+\.\d+} do
      #     "Value1: #{value1} - Value2: #{value2}""
      #   end
      # end
      # ```
      macro {{method.downcase.id}}(path, *args, **named_args, &)
        @[ART::{{method.capitalize.id}}(path: \{{path}}, constraints: \{{named_args[:constraints]}})]
        def {{method.downcase.id}}_\{{path.gsub(/\W/, "_").id}}(\{{*args}}) : \{{named_args[:return_type] || String}}
          \{{yield}}
        end
      end
    {% end %}
  {% end %}
end
