# Routing

Athena's routing is unique in two key areas:

* Route Definition - Defined by adding specific annotations to methods, which acts as the action to the route.  
  * This can allow for added type/compile time safety, and ability to document the API's endpoints; just like a normal method.
* Parameters - Route path/body/query params are automatically casted to the correct types, based on that route's action's parameter types.

## Defining Routes

Routes are defined by adding a `@[Athena::Routing::{{HTTP_METHOD}}(path: "/")]` annotation to a controller instance method.  The controller should be a class that inherits from `Athena::Routing::Controller`.

**NOTE**: The controller/action names do not currently matter.

```Crystal
require "athena/routing"

# The `ControllerOptions` annotation can be applied to a controller to define a prefix to use for all routes within `self`.
@[Athena::Routing::ControllerOptions(prefix: "athena")]
class TestController < Athena::Routing::Controller
  # A GET endpoint with no params returning a `String`.
  # By default, responses automatically include a
  # `content-type: application/json` header.
  @[Athena::Routing::Get(path: "/me")]
  def get_me : String
    "Jim"
  end
    
  # A GET endpoint with no params returning `Nil`.
  # `Nil` return types are returned with a status
  # of 204 no content
  @[Athena::Routing::Get(path: "/no_content")]
  def get_no_content : Nil
    # Do stuff
  end

  # A GET endpoint with two `Int32` params returning an `Int32`.
  @[Athena::Routing::Get(path: "/add/:val1/:val2")]
  def add(val1 : Int32, val2 : Int32) : Int32
    val1 + val2
  end

  # A GET endpoint with an `String` route param, a required string query param returning a `String`.
  @[Athena::Routing::Get(path: "/event/:event_name/", query: {"time" => /\d:\d:\d/})]
  def event_time(event_name : String, time : String) : String
    "#{event_name} occured at #{time}"
  end

  # A GET endpoint with a param constraints.
  # The param must match the supplied regex or
  # it will not match and return a 404 error.
  @[Athena::Routing::Get(path: "/time/:time/", constraints: {"time" => /\d{2}:\d{2}:\d{2}/})]
  def get_constraint(time : String) : String
    time
  end

  # A POST endpoint with a route param and a body param returning a `Bool`.
  @[Athena::Routing::Post(path: "/test/:expected")]
  def post_body(expected : String, body : String) : Bool
    expected == body
  end

  # A POST endpoint with form data param.
  # Form data is supplied in the form of an `HTTP::Params` object
  # as a way to have a singular container for the data.
  @[Athena::Routing::Post(path: "/formData/:expected")]
  def form_data(body : HTTP::Params, expected : String) : Bool
    expected == body["name"]
  end
end

Athena::Routing.run

CLIENT = HTTP::Client.new "localhost", 8888
CLIENT.get "/athena/me"                         # => "Jim"
CLIENT.get "/athena/add/50/25"                  # => 75
CLIENT.get "/athena/event/foobar?time=1:1:1"    # => "foobar occured at 1:1:1"
CLIENT.get "/athena/time/12:45:30"              # => "12:45:30"
CLIENT.get "/athena/time/12:aa:30"              # => 404 not found
CLIENT.get "/no_content"                        # => 204 no content

# If no `Content-Type` header is provided, the type of
# the body is assumed to be `text/plain`.
CLIENT.post "/athena/test/foo", body: "foo"     # => true
CLIENT.post "/athena/formData/foo", body: "foo" # => true
```

Note that the return type of each action is an actual type, not just a `String`.  Serialization is handled by `CrSerializer`.  This allows the actions to be clean and only focus on accomplishing the task of that action, while letting the serialization happen behind the scenes.

The param placeholder names **_MUST_** match the parameter names of the action.  The order in which the action's parameters are defined does not matter.

### Undefined Route

If a request is made to a route that has not been declared, a 404 error is returned with a body like:

```JSON
{
  "code": 404,
  "message": "No route found for 'GET /fake/route'"
}
```

### Default Route Values

A default value can be assigned to an action param.  If that route param is declared as optional, that value will be used if value is not supplied.  

```Crystal
require "athena/routing"

class MyController < Athena::Routing::Controller 
  @[Athena::Routing::Get(path: "/posts/(:page)")]
  def default_value(page : Int32? = 99) : Int32?
    page
  end
end

Athena::Routing.run

CLIENT = HTTP::Client.new "localhost", 8888
CLIENT.get "/posts" # => 99
CLIENT.get "/posts/12" # => 12
```

**NOTE:** This suffers from the same limitation as a Radix tree in that two routes cannot share the same route, where one route has an optional param at the same place another has a required param.  However, it would be considered a bad practice if two routes matched two different actions, especially with route constraints.

### Accessing Request/Response
The current request/response can be accessed from within a controller action via the `get_request` and `get_response` methods inherited from Athena's parent class.

This can be used to add custom headers, or to set a token in a cookie for example, within any action; without having to set a callback scoped to that specific action.

### Exception Handling

Athena provides an `AthenaException` class that can be used for raising custom exceptions with consistent JSON output, as well as setting the response status code.  Athena also provides convenience exception classes for common HTTP errors.  A full list can be found in the [API Docs](https://blacksmoke16.github.io/athena/Athena/Routing/Exceptions.html). 

```crystal
raise Athena::Routing::Exceptions::NotFoundException.new "User not found"
```

By default, Athena will catch and handle most errors related to param conversion, validation, JSON parsing, and `AthenaException`.  If the exception is not one of these, Athena will throw a 500 Internal Server Error.

Custom error handling can be defined on a controller, or group of controllers by utilizing inheritance.  For example.

```crystal
class FakeController < Athena::Routing::Controller
  def self.handle_exception(exception : Exception, ctx : HTTP::Server::Context)
    if exception.is_a? DivisionByZeroError
      throw 400, %({"code": 400, "message": "#{exception.message}"})
    end

    super
  end
end
```

The method accepts the exception that has been raised, and the server context.  This allows for centralized exception handling of custom exceptions, allowing errors to be handled at different levels, while still allowing action specific `begin/rescue` blocks. 

Any exceptions that happen within `FakeController` will first pass through  `FakeController.handle_exception`, which handles the `DivisionByZeroError`.  The `throw` macro is used to return a response with given *status code* and *body*, if it is of that type.  Otherwise, if the exception does not "match" any logic in the custom handler, calling `super` would call the parent's error handler, in this case Athena's default (but could also be another inherited controller), which would pass the exception to Athena to process.  If the exception does not "match" any rescued exceptions there either, then a 500 Internal Server Error would be thrown.

### Query Params

Query param are defined in the route annotation using the `query` field of type `Hash(String, Regex?)`.

```Crystal
require "athena/routing"

class TestController < Athena::Routing::Controller
  # An optional query param *time* with a default value and a constraint.
  @[Athena::Routing::Get(path: "/event/:event_name/", query: {"time" => /\d:\d:\d/})]
  def event_time(event_name : String, time : String? = "1:1:1") : String
    "#{event_name} occured at #{time}"
  end
  
  # A required query param *query* without a constraint.
  @[Athena::Routing::Get(path: "/event/:event_name/", query: {"query" => nil})]
  def event(event_name : String, query : String) : String
    "#{event_name} occured at #{query}"
  end
end

Athena::Routing.run
```

#### Optionality 

If a query param's type is nilable in the route's action parameters, it is considered to be optional.  If no default value is supplied, its value will simply be `nil` if it is not supplied.  If a query param's type is _not_ nilable; it is considered required and will raise a 400 if not supplied.

#### Constraints

A query param can have a `Regex` pattern attached to it.  If the query param is required and the pattern does not match, a 400 error will be raised.  If the param is optional and does not match, if no default value is supplied, its value will be `nil`.

### Route View

The `View` annotation controls how the return value of an endpoint is displayed. 

#### Groups

The `groups` field is used to specify which serialization groups this route should use.  See [CrSerializer Serialization Groups](https://github.com/Blacksmoke16/CrSerializer/blob/master/docs/serialization.md#serialization-groups) for more information.

```Crystal
require "athena/routing"

class UserController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "admin/users/:user_id")]
  @[Athena::Routing::View(groups: ["admin"])]
  @[Athena::Routing::ParamConverter(param: "user", pk_type: Int32, type: User, converter: Exists)]
  def get_user_admin(user : User) : User
    user
  end
end 

Athena::Routing.run
```

#### Renderer

A renderer controls how the object/value is serialized.  By default the object/value is serialized as JSON, with an `application/json` `Content-Type` header included by default.  Athena also has built in support for `YAML` and `ECR`.  

##### YAML

The `YAMLRenderer` defines a `text/x-yaml` `Content-Type` header and requires that the object has a `to_yaml` method, either from `YAML::Serializable` or a custom implementation.  

```Crystal
require "athena/routing"

class UserController < Athena::Routing::Controller
  # Assuming the found user's age is 17, name Bob, and password is abc123
  @[Athena::Routing::Get(path: "users/yaml/:user_id")]
  @[Athena::Routing::ParamConverter(param: "user", pk_type: Int32, type: User, converter: Exists)]
  @[Athena::Routing::View(renderer: Athena::Routing::Renderers::YAMLRenderer)]
  def get_user_yaml(user : User) : User
    user
  end
end  

Athena::Routing.run

GET /users/yaml/1 # => ---\age: 17\nname: Bob\npassword: abc123\n
```

##### ECR

The `ECRRenderer` defines a `text/html` `Content-Type` header and requires that the returned object implements a `to_s` method using `ECR.def_to_s`.  This allows for a simple way to render model specific pages.

```Crystal
require "athena/routing"

class UserController < Athena::Routing::Controller
  # Assuming the found user's age is 17, and name Bob.
  # Requires the return object implements `to_s` method using `ECR.def_to_s "user.ecr"`
  @[Athena::Routing::Get(path: "users/ecr/:user_id")]
  @[Athena::Routing::ParamConverter(param: "user", pk_type: Int32, type: User, converter: Exists)]
  @[Athena::Routing::View(renderer: Athena::Routing::Renderers::ECRRenderer)]
  def get_user_ecr(user : User) : User
    user
  end
end  

Athena::Routing.run

user.ecr
User <%= @name %> is <%= @age %> years old.

GET /users/ecr/1 # => User Bob is 17 years old.
```

###### ECR Files

ECR files can simply be rented by calling `ECR.render filename` as the return value of the action.  The action's return type must be declared as `String` and all required values for the ECR file must be supplied within the route's action.

```Crystal
require "athena/routing"

greeting.ecr
<!DOCTYPE html>
<html>
<body>

<h1>Hello <%= name %>!</h1>

<p>My first paragraph.</p>

</body>
</html>

test_controller.cr
class TestController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "/foo")]
  @[Athena::Routing::View(renderer: Athena::Routing::Renderers::ECRRenderer)]
  def foo : String
    name = "foo"
    ECR.render "src/greeting.ecr"
  end
end

Athena::Routing.run

GET /foo # =>  <!DOCTYPE html><html><body><h1>Hello foo!</h1><p>My first paragraph.</p></body></html>
```

#### Custom Renderers
If none of the built in renders does what is needed, custom renderers can be used by simply creating a struct that implements a `self.render(response : T, ctx : HTTP::Server::Context, groups : Array(String)) : String` method.

```crystal
require "athena/routing"

struct MyRenderer
  def self.render(response : T, ctx : HTTP::Server::Context, groups : Array(String) = [] of String) : String forall T    
    # Your custom logic
    # Add custom Content-Type headers
    # Handle object serialization
  end
end

class UserController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "users/custom/:user_id")]
  @[Athena::Routing::ParamConverter(param: "user", pk_type: Int64, type: User, converter: Exists)]
  @[Athena::Routing::View(renderer: MyRenderer)]
  def get_user_custom(user : User) : User
    user
  end
end

Athena::Routing.run
```

## Request Life-cycle Events

Two life-cycle events can be tapped:

- `OnRequest` - Executes before the route's action has executed.
- `OnResponse` - Executes after the route's action has executed.

Each event provides the request context in order to have access to the request and response data.

### Controller Scoped Callbacks

`Callback` annotations added on a class level controller method are scoped to the routes in that particular controller.  This could be useful for adding headers common to one grouping of routes.

```Crystal
require "athena/routing"

class MyController < Athena::Routing::Controller
  @[Athena::Routing::Callback(event: Athena::Routing::CallbackEvents::OnResponse)]
  def self.my_callback(context : HTTP::Server::Context) : Nil
    context.response.headers.add "X-MyController-Header", "true"
  end
end

Athena::Routing.run
```

#### Filtering

A callback can be set to only run on specific actions, or to exclude specific actions.  This can be achieved by adding an `only`, or `excluded` field to the `Callback` annotation.  The value to these fields is a `Array(String)` where each string is the name of an action.

```Crystal
@[Athena::Routing::Callback(event: Athena::Routing::CallbackEvents::OnResponse, only: ["get_all_users"])]
```

```Crystal
@[Athena::Routing::Callback(event: Athena::Routing::CallbackEvents::OnResponse, exclude: ["my_route"])]
```

The first callback would only run for the route who's action has the name `get_all_users`.  The second callback would run for all routes in that controller, except the route who's action has the name `my_route`.  

####  Inheritance

When a controller is inherited from, all callbacks defined on that controller will also be inherited.  This allows developers to smartly define their controllers to make use of inheritance to share common callbacks, such as for setting headers for public vs private routes.

The same idea also applies to methods.  Class methods can be defined on parent controllers so that each child controller has those methods defined.  Such as the `get_request`/`get_response` methods Athena defines by default.

Callbacks can also be defined to run on _all_ routes no matter which controller they are in.  This can be achieved by adding a callback action to the parent controller: `Athena::Routing::Controller`.  

This is most useful for adding `Content-Type` response headers, or CORs.  

Global callbacks can also be filtered if you wanted to exclude a specific route.

```Crystal
require "athena/routing"

class Athena::Routing::Controller
  @[Athena::Routing::Callback(event: Athena::Routing::CallbackEvents::OnResponse)]
  def self.global_callback(context : HTTP::Server::Context) : Nil
    context.response.headers.add "X-RESPONSE-GLOBAL", "true"
  end
end

Athena::Routing.run
```

## ParamConverter

All basic types, such as `Int`, `Float`, `String`, `Bool`, are natively converted from the request's params.  However in order to convert more complex types, such as a `User`, a `ParamConverter` must be specified on the action to specify how to resolve that type.  Multiple `ParamConverter` are also supported.

### Exists

The `Exists` converter takes a route param and attempts to resolve an object of `T` with that ID.  If no object is found a 404 JSON error is returned.

This converter requires that there is a `self.find(val : String) : self` method on `T` that either returns the corresponding object, or nil.  This can either be from an ORM library, or defined manually.

**NOTE:** The `Exists` converter requires an extra annotation field `pk_type`.  This should be set to the type of the primary key, or unique identifier, of the model/class.  This is used to convert the string value to the correct type for the `find` query.

```Crystal
require "athena/routing"

class UserController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "users/:user_id")]
  @[Athena::Routing::ParamConverter(param: "user", pk_type: Int32, type: User, converter: Exists)]
  def get_user(user : User) : String
    "This user is #{user.age} years old"
  end
end

Athena::Routing.run
```

The beauty of this is if you sent a request, `GET /users/123`, it would execute `User.find 123`, which would allow for the actual user object to be injected into the action.  It's that easy.  This removes a lot of boilerplate that would otherwise be required to handle the lookup/validation of ORM models from string route params.

#### Record Not Found

If the *find* method returns nil, indicating a record was not found, a 404 error is returned with a body like:

```JSON
{
    "code": 404,
    "message": "An item with the provided ID could not be found."
}
```

### RequestBody

The `RequestBody` converter will attempt to deserialize the JSON body of a request, into an object of `T`.

This converter requires that there is a `self.from_json(body : String) : self` method on `T` that will return an instance of `T` from the JSON string body of the request.  This, by default, is from `CrSerializer` but could also be something manually defined.

```Crystal
require "athena/routing"

class UserController < Athena::Routing::Controller
  @[Athena::Routing::Post(path: "users/")]
  @[Athena::Routing::ParamConverter(param: "user", type: User, converter: RequestBody)]
  def new_user(user : User) : User
    user.save
    user
  end
end

Athena::Routing.run
```

The beauty of this is mainly intended for POST/PUT endpoints as you would be able to set the body as a JSON representation of the user (from a front end form for example), have it auto deserialized into a `User` object for use within the action.  In order to save the user you would just have to call `user.save`.   This would work for both new and already persisted records.

#### Invalid Property Type

If the deserialization of the object fails due to a type mismatch; sending `{"age": "foo"}` where the `age` property should be an Int32, a 400 error is returned with a body like:

```JSON
{
  "code": 400,
  "message": "Expected 'age' to be int but got string"
}
```

#### Failed Validations

Upon deserialization, objects are validated against [CrSerializer's Validations](https://github.com/Blacksmoke16/CrSerializer/tree/master/docs#validations). If an object fails one of these validations, a 400 error is returned with a body like:

```JSON
{
  "code": 400,
  "message": "Validation tests failed",
  "errors": [
    "'age' should be greater than 0"
  ]
}
```

### FormData

The `FormData` converter will attempt to deserialize the request's form data, into an object of `T`.

This converter requires that there is a `from_form_data(params : HTTP::Params) : self` method on `T` that will return an instance of `T` from `HTTP::Params` object parsed from the request body.

```Crystal
require "athena/routing"

class User
  ...
  
  def self.from_form_data(form_data : HTTP::Params) : self
    obj = new
    obj.age = form_data["age"].to_i
    obj.name = form_data["name"]
    obj
  end
end

class UserController < Athena::Routing::Controller
  # Form data: age=19&name=Jim
  @[Athena::Routing::Post(path: "users/")]
  @[Athena::Routing::ParamConverter(param: "user", type: User, converter: FormData)]
  def new_user(user : User) : User
    user.name # => "Jim"
    user.age # => 19
    user
  end
end

Athena::Routing.run
```

While this is not as clean as using JSON, it provides a decent way to handle form data for legacy or other reasons.

### Custom Converter

A custom converter can also be defined to perform special logic.  Simply create a struct, with a generic, that implements a class method `convert(value : String) : T`.  

```Crystal
struct MyConverter(T)
  def self.convert(param_value : String) : T
    # Your custom logic
    model
  end
end
```

This then can be used like `@[Athena::Routing::ParamConverter(param: "user", type: User, converter: MyConverter)]`

## CORS

Athena provides an easy, flexible way to enable CORS for your application's endpoints.  To enable cors, set `enabled` to `true` in your `athena.yml` file in the root of your problem.  If a config file was not created upon installing Athena, created before CORS support was released for example, an example file is available [here](https://github.com/Blacksmoke16/athena/blob/master/athena.yml). 

By default the file should be named `athena.yml` and be located at the root of the project.  This can be overridden by providing a path when starting Athena. 

```crystal
Athena::Routing.run(config_path: "path/to/config")
```
A recommended option would be to have multiple config files for each environment, then use an ENV variable to supply the path.  
### Strategy

The `strategy` determines how CORS settings get applied.  

* blacklist (default) - Will apply the defaults to _ALL_ routes, unless explicitly disabled or overridden.  
* whitelist - Will _NOT_ apply the defaults to _ANY_ routes, unless explicitly set with a group.

### Groups

CORS groups are similar to [CrSerializer Serialization Groups](https://github.com/Blacksmoke16/CrSerializer/blob/master/docs/serialization.md#serialization-groups), but for CORS.  They give the ability to share settings with `defaults` but override some settings to be specific to that group.

```yaml
# Config file for Athena.
---
routing:
  cors:
    enabled: true
    strategy: blacklist
    defaults: &defaults
      allow_origin: DEFAULT_DOMAIN
      expose_headers:
        - DEFAULT1_EH
        - DEFAULT2_EH
      max_age: 123
      allow_credentials: false
      allow_methods:
        - GET
      allow_headers:
        - DEFAULT_AH
    groups:
      class_overload:
        <<: *defaults
        allow_origin: OVERLOAD_DOMAIN
      action_overload:
        <<: *defaults
        allow_origin: ACTION_DOMAIN
        allow_credentials: true
```

In this example we have two custom groups `class_overload` and `action_overload`.  Both are inherited from the `defaults`.  `class_overload` overrides the `allow_origin` header value, while `action_overload` overrides both the `allow_origin` and `allow_credentials` headers.

A `cors_group` can be added to any controller/action.  

```crystal
@[Athena::Routing::ControllerOptions(cors: "class_overload")]
class OverloadController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "class_overload")]
  def cors_class_overload : String
    "class_overload"
  end

  @[Athena::Routing::Get(path: "action_overload", cors: "action_overload")]
  def cors_action_overload : String
    "action_overload"
  end

  @[Athena::Routing::Get(path: "disable_overload", cors: false)]
  def cors_disable_overload : String
    "disable_overload"
  end
end
```

In this example, `cors_class_overload` `cors_group` will be applied to _ALL_ routes within the controller, unless a specific action overrides it.  `cors_action_overload` would use the `action_overload` `cors_group`, while `cors_disable_overload` has CORS disabled.

The order of precedence is `action > controller > defaults`, where a `cors_group` on an action would override the group of the controller; and the group on the controller would override the defaults.  Inheritance also works.  `cors_groups` added to a parent controller, will also be the group for child controllers, unless overridden on an action or a controller that is further down.

The easiest setup would be to update the `defaults` with your settings and use the `blacklist` `strategy`. 


## Custom Handlers

By default Athena sets up the required handlers behind the scenes if no custom handlers are supplied.  

In order to use custom handlers, first create a class that inherits from `Athena::Routing::Handlers::Handler` and implements a `def handle(ctx : HTTP::Server::Context, action : Athena::Routing::Action, config : Athena::Config::Config) : Nil`.  The base Athena Handler class extends the default `HTTP::Handler` class to expose extra information for use.  Each handler has access to the server context, the action that was matched, and the config object from the config file.

```crystal
require "athena/routing"

class MyHandler < Athena::Routing::Handlers::Handler
  def handle(ctx : HTTP::Server::Context, action : Athena::Routing::Action, config : Athena::Config::Config) : Nil
    # Do custom logic here such as:
    # * Add unique id to response
    # * Set response time
    # * Parse auth headers
      
    # Call this to call the next handler
    handle_next
  rescue ex
    # Call the action's exception handler on error.
    action.controller.handle_exception ex, action.method
  end
end

# Other setup
...

# Run the server with the custom defines handlers.
# The first handler in the array will run first.
Athena::Routing.run(
  handlers: [
    # Create a new instance of the handler.
    MyHandler.new,
    # Optional but required if CORS is enabled in the config,
    # also free to implement your own CORS handler.
    Athena::Routing::Handlers::CorsHandler.new,
    # This handler is required, but can be placed where ever you want.
    # This is what executes the route's action.
    Athena::Routing::Handlers::ActionHandler.new,
  ]
)
```

