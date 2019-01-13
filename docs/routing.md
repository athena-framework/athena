# Routing

Athena's routing is unique in two key areas:

* Route Definition - Defined by adding specific annotations to methods, which acts as the action to the route.  
  * This can allow for added type/compile time safety, and ability to document the API's endpoints; just like a normal method.
* Parameters - Route path/body params can are automatically casted to the correct types, based on that route's action's parameter types.

## Defining Routes

Routes are defined by adding a `@[Athena::Routing::{{HTTP_METHOD}}(path: "/")]` annotation to a controller's class method.  The class should inherit from either `Athena::Routing::ClassController` or `Athena::Routing::StructController` if the controller is a `Class` or `Struct`.

**NOTE**: The controller/action names do not currently matter.

```Crystal
require "athena/routing"

class TestController < Athena::Routing::ClassController
  # A GET endpoint with no params returning a string.
  @[Athena::Routing::Get(path: "/me")]
  def self.get_me : String
    "Jim"
  end

  # A GET endpoint with two Int params returning an Int32.
  @[Athena::Routing::Get(path: "/add/:val1/:val2")]
  def self.add(val1 : Int32, val2 : Int32) : Int32
    val1 + val2
  end
  
  # A GET endpoint with a param constraints.
  # The param must match the supplied regex or
  # it will not match and return a 404 error.
  @[Athena::Routing::Get(path: "/time/:time/", constraints: /\d{2}:\d{2}:\d{2}/)]
  def self.add(time : String) : String
    time
  end
    
  # A POST endpoint with a route param and a body param returning a Bool.
  #
  # NOTE: The post body param is always the last defined action argument.
  @[Athena::Routing::Post(path: "/test/:expected")]
  def self.add(expected : String, actual : String) : Bool
    expected == actual
  end
  
  # A POST endpoint with form data param.
  # Form data is returned in the form of an `HTTP::Params` object
  # as a way to have a singular container for the data.
  #
  # NOTE: The post body param is always the last defined action argument.
  @[Athena::Routing::Post(path: "/test/")]
  def self.add(data : HTTP::Params) : Bool
    expected == actual
  end
end

CLIENT = HTTP::Client.new "localhost", 8888
CLIENT.get "/me" # => Jim
CLIENT.get "/add/50/25" # => 75
CLIENT.get "/time/12:45:30" # => "12:45:30"
CLIENT.get "/time/12:aa:30" # => 404 not found

# If no `Content-Type` header is provided, the type of
# the body is assumed to be `text/plain`.
CLIENT.post "/test/foo", body: "foo" # => true
```

Note that the return type of each action is an actual type, not just a `String`.  Serialization is handled by `CrSerializer`.  This allows the actions to be clean and only focus on accomplishing the task of that action, while letting the serialization happen behind the scenes.

### Undefined Route

If a request is made to a route that has not been declared, a 404 error is returned with a body like:

```JSON
{
  "code": 404,
  "message": "No route found for 'GET /fake/route'"
}
```

### Default Route Values

A default value can be assigned to an action param.  If that route param is declared as optional, that value will be used if the optional param is not given.  

```Crystal
require "athena/routing"

class MyController < Athena::Routing::ClassController 
  @[Athena::Routing::Get(path: "/posts/(:page)")]
  def self.default_value(page : Int32 = 99) : Int32
    page
  end
end

CLIENT = HTTP::Client.new "localhost", 8888
CLIENT.get "/posts" # => 99
CLIENT.get "/posts/12" # => 12
```

**NOTE:** This suffers from the same limitation as a Radix tree in that two routes cannot share the same route, where one route has an optional param at the same place another has a required param.  However it would be considered a bad practice if two routes matched two different actions, especially with route constraints.

### Route View

The `View` annotation controls how the return value of an endpoint is displayed. 

#### Groups

The `groups` field is used to specify which serialization groups this route should use.  See [CrSerializer Serialization Groups](https://github.com/Blacksmoke16/CrSerializer/blob/master/docs/serialization.md#serialization-groups) for more information.

```Crystal
require "athena/routing"

@[Athena::Routing::Get(path: "admin/users/:id")]
@[Athena::Routing::View(groups: ["admin"])]
@[Athena::Routing::ParamConverter(param: "user", type: User, converter: Exists)]
def self.get_user_admin(user : User) : User
  user
end
```

#### Renderer

A renderer controls how the object/value is serialized.  By default the object/value is serialized as JSON.  Athena also has built in support for `YAML` and `ECR`.  

##### YAML

The `YAMLRenderer` requires that the object has a `to_yaml` method, either from `YAML::Serializable` or a custom implementation.  

```Crystal
require "athena/routing"

class UserController < Athena::Routing::ClassController
  # Assuming the found user's age is 17, name Bob, and password is abc123
  @[Athena::Routing::Get(path: "users/yaml/:id")]
  @[Athena::Routing::ParamConverter(param: "user", type: User, converter: Exists)]
  @[Athena::Routing::View(renderer: YAMLRenderer)]
  def self.get_user_yaml(user : User) : User
    user
  end
end  
GET /users/yaml/1 # => ---\age: 17\nname: Bob\npassword: abc123\n
```

##### ECR

The `ECRRenderer` requires that the returned object implements a `to_s` method using `ECR.def_to_s`.  This allows for a simple way to render model specific pages.

```Crystal
require "athena/routing"

class UserController < Athena::Routing::ClassController
  # Assuming the found user's age is 17, and name Bob.
  # Requires the return object implements `to_s` method using `ECR.def_to_s "user.ecr"`
  @[Athena::Routing::Get(path: "users/ecr/:id")]
  @[Athena::Routing::ParamConverter(param: "user", type: User, converter: Exists)]
  @[Athena::Routing::View(renderer: ECRRenderer)]
  def self.get_user_ecr(user : User) : User
    user
  end
end  

user.ecr
User <%= @name %> is <%= @age %> years old.

GET /users/ecr/1 # => User Bob is 17 years old.
```

#### String Return Type

Actions that return a string are dumped straight into the response body, without going through any processing by any renderer.  This allows for a route to render a ECR file.  However, all required values for the ECR file must be supplied within the route's action.

```Crystal
require "athena/routing"

class Test < Athena::Routing::ClassController
  # This return `Hello foo!` when that route is requested.
  @[Athena::Routing::Get(path: "/foo")]
  def self.foo : String
    name = "foo"
    ECR.render "./src/greeting.ecr"
  end
end
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

class MyController < Athena::Routing::ClassController
  @[Athena::Routing::Callback(event: Athena::Routing::CallbackEvents::OnResponse)]
  def self.my_callback(context : HTTP::Server::Context) : Nil
    context.response.headers.add "X-MyController-Header", "true"
  end
end
```

#### Filtering

A callback can be set to only run on specific actions, or to exclude specific actions.  This can be achieved by add an `only`, or `excluded` field to the `Callback` annotation.  The value to these fields is a `Array(String)` where each string is the name of an action.

```Crystal
@[Athena::Routing::Callback(event: Athena::Routing::CallbackEvents::OnResponse, only: ["get_all_users"])]
```

```Crystal
@[Athena::Routing::Callback(event: Athena::Routing::CallbackEvents::OnResponse, exclude: ["my_route"])]
```

The first callback would only run for the route who's action has the name `get_all_users`.  The second callback would run for all routes in that controller, except the route who's action has the name `my_route`.  

### Global Callbacks

Callbacks can also be defined to run on _all_ routes no matter which controller they are in.  This can be achieved by adding a callback action to the parent controller classes: `Athena::Routing::Routing::ClassController` or `Athena::StructController`.  

This is most useful for adding `Content-Type` response headers, or CORs.  

Global callbacks can also be filtered if you wanted to exclude a specific route.

```Crystal
require "athena/routing"

class Athena::Routing::ClassController
  @[Athena::Routing::Callback(event: Athena::Routing::CallbackEvents::OnResponse)]
  def self.global_callback(context : HTTP::Server::Context) : Nil
    context.response.headers.add "X-RESPONSE-GLOBAL", "true"
  end
end
```

Additional methods may be added to the parent class/struct that would be available to all route actions.  

## ParamConverter

All basic types, such as `Int`, `Float`, `String`, `Bool`, are natively converted from the request's params.  However in order to convert more complex types, such as a `User`, a `ParamConverter` must be specified on the action to specify how to resolve that type.  

### Exists

The `Exists` converter takes a route param and attempts to resolve an object of `T` with that ID.  If no object is found a 404 JSON error is thrown/returned.

This converter requires that there is a `self.find(val : String) : self` method on `T` that either returns the corresponding object, or nil.  This can either be from an ORM library, or defined manually on the class.

```Crystal
require "athena/routing"

class UserController < Athena::Routing::ClassController
  @[Athena::Routing::Get(path: "users/:id")]
  @[Athena::Routing::ParamConverter(param: "user", type: User, converter: Exists)]
  def self.get_user(user : User) : String
    "This user is #{user.age} years old"
  end
end
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

This converter requires that there is a `self.deserialize(body : String) : self` method on `T` that will return an instance of `T` from the string body of the request.  This, by default, is from `CrSerializer` but could also be something manually defined on the class.

```Crystal
require "athena/routing"

class UserController < Athena::Routing::ClassController
  @[Athena::Routing::Post(path: "users/")]
  @[Athena::Routing::ParamConverter(param: "user", type: User, converter: RequestBody)]
  def self.new_user(user : User) : User
    user.save
    user
  end
end
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

This converter requires that there is a `self.from_form_data(body : String) : self` method on `T` that will return an instance of `T` from the string body of the request.  This, by default, is from `CrSerializer` but could also be something manually defined on the class.

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

class UserController < Athena::Routing::ClassController
  # Form data: age=19&name=Jim
  @[Athena::Routing::Post(path: "users/")]
  @[Athena::Routing::ParamConverter(param: "user", type: User, converter: FormData)]
  def self.new_user(user : User) : User
    user.name # => "Jim"
    user.age # => 19
    user
  end
end
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
