# Documentation

Athena's main focus is for JSON APIs.  Athena is unique in a two key areas:

* Route Definition - Defined by adding specific annotations to methods, which acts as the action to the route.  
  * This can allow for added type/compile time safety, and ability to document the API's endpoints; just like a normal method.
* Parameters - Route path/body params can are automatically casted to the correct types, based on that route's action's parameter types.

## Routes

Routes are defined by adding a `@[Athena::{{HTTP_METHOD}}(path: "/")]` annotation to a controller's class method.  The class should inherit from either `Athena::ClassController` or `Athena::StructController` if the controller is a `Class` or `Struct`.

**NOTE**: The controller/action names do not currently matter.

```Crysta
class TestController < Athena::ClassController
  # A GET endpoint with no params returning a string.
  @[Athena::Get(path: "/me")]
  def self.get_me : String
    "Jim"
  end

  # A GET endpoint with two Int params returning an Int32.
  @[Athena::Get(path: "/add/:val1/:val2")]
  def self.add(val1 : Int32, val2 : Int32) : Int32
    val1 + val2
  end
    
  # A POST endpoint with a route param and a body param returning a Bool.
  # NOTE: The post body param is always the last defined action argument.
  # NOTE: Query params/form data are not supported at this moment.
  @[Athena::Post(path: "/test/:expected")]
  def self.add(expected : String, actual : String) : Bool
    expected == actual
  end
end

CLIENT = HTTP::Client.new "localhost", 8888
CLIENT.get "/me" # => Jim
CLIENT.get "/add/50/25" # => 75

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
class MyController < Athena::ClassController 
  @[Athena::Get(path: "/posts/(:page)")]
  def self.default_value(page : Int32 = 99) : Int32
    page
  end
end

CLIENT = HTTP::Client.new "localhost", 8888
CLIENT.get "/posts" # => 99
CLIENT.get "/posts/12" # => 12
```

**NOTE:** This suffers from the same limitation as a Radix tree in that two routes cannot share the same route, where one route has an optional param at the same place another has a required param.

### Route View

The `View` annotation controls how the return value of an endpoint is displayed.  The `groups` field is used to specify which serialization groups this route should use.  See [CrSerializer Serialization Groups](https://github.com/Blacksmoke16/CrSerializer/blob/master/docs/serialization.md#serialization-groups) for more information.

```Crystal
  @[Athena::Get(path: "admin/users/:id")]
  @[Athena::View(groups: ["admin"])]
  @[Athena::ParamConverter(param: "user", type: User, converter: Exists)]
  def self.get_user_admin(user : User) : User
    user
  end
```



## Request Life-cycle Events

Two life-cycle events can be tapped:

* `ON_REQUEST` - Executes before the route's action has executed.

* `ON_RESPONSE` - Executes after the route's action has executed.

Each event provides the request context in order to have access to the request and response data.

### Controller Scoped Callbacks

`Callback` annotations added on a class level controller method are scoped to the routes in that particular controller.  This could be useful for adding headers common to one grouping of routes.

```Crysta
class MyController < Athena::ClassController
  @[Athena::Callback(event: CallbackEvents::ON_RESPONSE)]
  def self.my_callback(context : HTTP::Server::Context) : Nil
    context.response.headers.add "X-MyController-Header", "true"
  end
end
```

#### Filtering

A callback can be set to only run on specific actions, or to exclude specific actions.  This can be achieved by add an `only`, or `excluded` field to the `Callback` annotation.  The value to these fields is a `Array(String)` where each string is the name of an action.

```Crystal
@[Athena::Callback(event: CallbackEvents::ON_RESPONSE, only: ["get_all_users"])]
```

```Crystal
@[Athena::Callback(event: CallbackEvents::ON_RESPONSE, exclude: ["my_route"])]
```

The first callback would only run for the route who's action has the name `get_all_users`.  The second callback would run for all routes in that controller, except the route who's action has the name `my_route`.  

### Global Callbacks

Callbacks can also be defined to run on _all_ routes no matter which controller they are in.  This can be achieved by adding a callback action to the parent controller classes: `Athena::ClassController` or `Athena::StructController`.  

This is most useful for adding `Content-Type` response headers, or CORs.  

Global callbacks can also be filtered if you wanted to exclude a specific route.

```Crystal
class Athena::ClassController
  @[Athena::Callback(event: CallbackEvents::ON_RESPONSE)]
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

This converter assumes that there is a *find* method on `T` that either returns the corresponding object, or nil.  This can either be from an ORM library, or defined manually on the class.

```Crystal
class UserController < Athena::ClassController
  @[Athena::Get(path: "users/:id")]
  @[Athena::ParamConverter(param: "user", type: User, converter: Exists)]
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

```Crystal
class UserController < Athena::ClassController
  @[Athena::Post(path: "users/")]
  @[Athena::ParamConverter(param: "user", type: User, converter: RequestBody)]
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

This then can be used like `@[Athena::ParamConverter(param: "user", type: User, converter: MyConverter)]`






