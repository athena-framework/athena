## HTTP Exceptions

Exception handling in the Athena Framework is similar to exception handling in any Crystal program, with the addition of a new unique exception type, [ATH::Exception::HTTPException](/Framework/Exceptions/HTTPException).
Custom `HTTP` errors can also be defined by inheriting from `ATH::Exception::HTTPException` or a child type.
A use case for this could be allowing additional data/context to be included within the exception.

Non `ATH::Exception::HTTPException` exceptions are represented as a `500 Internal Server Error`.

When an exception is raised, the framework emits the [Exception](./middleware.md#8-exception-handling) event to allow an opportunity for it to be handled.
By default these exceptions will return a `JSON` serialized version of the exception, via [ATH::ErrorRenderer](/Framework/ErrorRenderer), that includes the message and code; with the proper response status set.
If the exception goes unhandled, i.e. no listener sets an [ATH::Response](/Framework/Response) on the event, then the request is finished and the exception is re-raised.

```crystal
require "athena"

class ExampleController < ATH::Controller
  @[ARTA::Get("/divide/{num1}/{num2}")]
  def divide(num1 : Int32, num2 : Int32) : Int32
    num1 // num2
  end

  @[ARTA::Get("/divide_rescued/{num1}/{num2}")]
  def divide_rescued(num1 : Int32, num2 : Int32) : Int32
    num1 // num2
    # Rescue a non `ATH::Exception::HTTPException`
  rescue ex : DivisionByZeroError
    # in order to raise an `ATH::Exception::HTTPException` to provide a better error message to the client.
    raise ATH::Exception::BadRequest.new "Invalid num2:  Cannot divide by zero"
  end
end

ATH.run

# GET /divide/10/0          # => {"code":500,"message":"Internal Server Error"}
# GET /divide_rescued/10/0  # => {"code":400,"message":"Invalid num2:  Cannot divide by zero"}
# GET /divide_rescued/10/10 # => 1
```

## Logging

Logging is handled via Crystal's [Log](https://crystal-lang.org/api/Log.html) module. Athena Framework logs when a request matches a controller action, as well as any exception. This of course can be augmented with additional application specific messages.

```bash
2022-01-08T20:44:18.134423Z   INFO - athena.routing: Server has started and is listening at http://0.0.0.0:3000
2022-01-08T20:44:19.773376Z   INFO - athena.routing: Matched route 'example_controller_divide' -- route: "example_controller_divide", route_parameters: {"_route" => "example_controller_divide", "_controller" => "ExampleController#divide", "num1" => "10", "num2" => "0"}, request_uri: "/divide/10/0", method: "GET"
2022-01-08T20:44:19.892748Z  ERROR - athena.routing: Uncaught exception #<DivisionByZeroError:Division by 0> at /usr/lib/crystal/int.cr:141:7 in 'check_div_argument'
Division by 0 (DivisionByZeroError)
  from /usr/lib/crystal/int.cr:141:7 in 'check_div_argument'
  from /usr/lib/crystal/int.cr:105:5 in '//'
  from src/components/framework/src/athena.cr:206:5 in 'divide'
  from src/components/framework/src/ext/routing/annotation_route_loader.cr:8:5 in '->'
  from /usr/lib/crystal/primitives.cr:266:3 in 'execute'
  from src/components/framework/src/route_handler.cr:76:16 in 'handle_raw'
  from src/components/framework/src/route_handler.cr:19:5 in 'handle'
  from src/components/framework/src/athena.cr:161:27 in '->'
  from /usr/lib/crystal/primitives.cr:266:3 in 'process'
  from /usr/lib/crystal/http/server.cr:515:5 in 'handle_client'
  from /usr/lib/crystal/http/server.cr:468:13 in '->'
  from /usr/lib/crystal/primitives.cr:266:3 in 'run'
  from /usr/lib/crystal/fiber.cr:98:34 in '->'
  from ???

2022-01-08T20:45:10.803001Z   INFO - athena.routing: Matched route 'example_controller_divide_rescued' -- route: "example_controller_divide_rescued", route_parameters: {"_route" => "example_controller_divide_rescued", "_controller" => "ExampleController#divide_rescued", "num1" => "10", "num2" => "0"}, request_uri: "/divide_rescued/10/0", method: "GET"
2022-01-08T20:45:10.923945Z   WARN - athena.routing: Uncaught exception #<Athena::Framework::Exception::BadRequest:Invalid num2:  Cannot divide by zero> at src/components/framework/src/athena.cr:215:5 in 'divide_rescued'
Invalid num2:  Cannot divide by zero (Athena::Framework::Exception::BadRequest)
  from src/components/framework/src/athena.cr:215:5 in 'divide_rescued'
  from src/components/framework/src/ext/routing/annotation_route_loader.cr:8:5 in '->'
  from /usr/lib/crystal/primitives.cr:266:3 in 'execute'
  from src/components/framework/src/route_handler.cr:76:16 in 'handle_raw'
  from src/components/framework/src/route_handler.cr:19:5 in 'handle'
  from src/components/framework/src/athena.cr:161:27 in '->'
  from /usr/lib/crystal/primitives.cr:266:3 in 'process'
  from /usr/lib/crystal/http/server.cr:515:5 in 'handle_client'
  from /usr/lib/crystal/http/server.cr:468:13 in '->'
  from /usr/lib/crystal/primitives.cr:266:3 in 'run'
  from /usr/lib/crystal/fiber.cr:98:34 in '->'
  from ???

2022-01-08T20:45:14.132652Z   INFO - athena.routing: Matched route 'example_controller_divide_rescued' -- route: "example_controller_divide_rescued", route_parameters: {"_route" => "example_controller_divide_rescued", "_controller" => "ExampleController#divide_rescued", "num1" => "10", "num2" => "10"}, request_uri: "/divide_rescued/10/10", method: "GET"
```

#### Customization

By default the Athena Framework utilizes the default [Log::Formatter](https://crystal-lang.org/api/Log/Formatter.html) and [Log::Backend](https://crystal-lang.org/api/Log/Backend.html)s Crystal defines. This of course can be customized via interacting with Crystal's [Log](https://crystal-lang.org/api/Log.html) module. It is also possible to control what exceptions, and with what severity, will be logged by redefining the `log_exception` method within [ATH::Listeners::Error](/Framework/Listeners/Error).

TIP: Since `ATH::Listeners::Error` logs already include the error message and first line of the trace, consider defining a custom [Log Formatter](https://crystal-lang.org/api/Log/Formatter.html) that excludes the `exception` to have shorter, single line error logs in console:
```crystal
Log.define_formatter SingleLineFormatter, "#{timestamp} #{severity} - #{source(after: ": ")}#{message}" \
                                          "#{data(before: " -- ")}#{context(before: " -- ")}"

# 2024-03-04T05:30:29.329041Z   INFO - athena.framework: Server has started and is listening at http://0.0.0.0:3000
# 2024-03-04T05:30:37.568264Z   INFO - athena.framework: Matched route 'view_controller_bar' -- route: "view_controller_bar", route_parameters: {"_route" => "view_controller_bar", # "_controller" => "ViewController#bar"}, request_uri: "/bar", method: "GET"
# 2024-03-04T05:30:40.280070Z   INFO - athena.framework: Matched route 'view_controller_foo' -- route: "view_controller_foo", route_parameters: {"_route" => "view_controller_foo", # "_controller" => "ViewController#foo"}, request_uri: "/foo", method: "GET"
# 2024-03-04T05:30:40.351541Z  ERROR - athena.framework: Uncaught exception #<Athena::Framework::Exception::Logic:Failed to serialize response body. Did you forget to include # either `JSON::Serializable` or `ASR::Serializable`?> at src/components/framework/src/view/view_handler.cr:166:21 in 'init_response'
# 2024-03-04T05:30:41.281275Z   INFO - athena.framework: Matched route 'view_controller_foo' -- route: "view_controller_foo", route_parameters: {"_route" => "view_controller_foo", # "_controller" => "ViewController#foo"}, request_uri: "/foo", method: "GET"
# 2024-03-04T05:30:41.282632Z  ERROR - athena.framework: Uncaught exception #<Athena::Framework::Exception::Logic:Failed to serialize response body. Did you forget to include # either `JSON::Serializable` or `ASR::Serializable`?> at src/components/framework/src/view/view_handler.cr:166:21 in 'init_response'
# 2024-03-04T05:30:43.886367Z   INFO - athena.framework: Matched route 'view_controller_bar' -- route: "view_controller_bar", route_parameters: {"_route" => "view_controller_bar", # "_controller" => "ViewController#bar"}, request_uri: "/bar", method: "GET"
```
