module Athena::Routing
  # Defines a GET endpoint.
  #
  # A corresponding `HEAD` endpoint is also defined.
  #
  # ## Fields
  # * path : `String` - The path for the endpoint, may also be provided as the first positional argument.
  # * constraints : `Hash(String, Regex)` - A mapping between a route's path parameters and its constraints.
  #
  # ## Example
  # ```
  # @[ART::Get(path: "/users/:id")]
  # def get_user(id : Int32) : Nil
  # end
  # ```
  annotation Get; end

  # Defines a POST endpoint.
  #
  # ## Fields
  # * path : `String` - The path for the endpoint, may also be provided as the first positional argument.
  # * constraints : `Hash(String, Regex)` - A mapping between a route's path parameters and its constraints.
  #
  # ## Example
  # ```
  # @[ART::Post(path: "/users")]
  # def new_user : Nil
  # end
  # ```
  annotation Post; end

  # Defines a PUT endpoint.
  #
  # ## Fields
  # * path : `String` - The path for the endpoint, may also be provided as the first positional argument.
  # * constraints : `Hash(String, Regex)` - A mapping between a route's path parameters and its constraints.
  #
  # ## Example
  # ```
  # @[ART::Put(path: "/users/:id")]
  # def update_user(id : Int32) : Nil
  # end
  # ```
  annotation Put; end

  # Defines a PATCH endpoint.
  #
  # ## Fields
  # * path : `String` - The path for the endpoint, may also be provided as the first positional argument.
  # * constraints : `Hash(String, Regex)` - A mapping between a route's path parameters and its constraints.
  #
  # ## Example
  # ```
  # @[ART::Patch(path: "/users/:id")]
  # def partial_update_user(id : Int32) : Nil
  # end
  # ```
  annotation Patch; end

  # Defines a DELETE endpoint.
  #
  # ## Fields
  # * path : `String` - The path for the endpoint, may also be provided as the first positional argument.
  # * constraints : `Hash(String, Regex)` - A mapping between a route's path parameters and its constraints.
  #
  # ## Example
  # ```
  # @[ART::Delete(path: "/users/:id")]
  # def delete_user(id : Int32) : Nil
  # end
  # ```
  annotation Delete; end

  # Applies an `ART::ParamConverterInterface` to a given parameter.
  #
  # NOTE: The related action argument's type must be compatible with the converter's return type.
  #
  # See `ART::ParamConverterInterface` for more information on defining a param converter.
  #
  # ## Fields
  # * param : `String` - The param that should be converted, may also be provided as the first positional argument.
  # * converter : `ART::ParamConverterInterface.class` - The `ART::ParamConverterInterface` that should be used to convert this parameter.
  #
  # ## Example
  # ```
  # @[ART::ParamConverter(param: "user", converter: DBConverter(User))]
  # @[ART::Get(path: "/users/:id")]
  # def get_user(user : User) : Nil
  # end
  # ```
  annotation ParamConverter; end

  # Defines a `ART::Parameters::QueryParameter` tied to a given route.
  #
  # The type of the query param is derived from the type restriction of the associated controller action argument.
  #
  # A non-nilable type denotes it as required.  If the parameter is not supplied, and no default value is assigned, an `ART::Exceptions::BadRequest` exception is raised.
  # A nilable type denotes it as optional.  If the parameter is not supplied (or could not be converted), and no default value is assigned, it is `nil`.
  #
  # ## Fields
  # * name : `String` - The name of the query parameter, may also be provided as the first positional argument.
  # * constraints : `Regex` - A pattern the query pram must match to be considered valid.
  # * converter : `ART::ParamConverterInterface.class` - The `ART::ParamConverterInterface` that should be used to convert this parameter.
  #
  # ## Example
  # ```
  # @[ART::QueryParam(name: "value")]
  # @[ART::Get(path: "/example")]
  # def get_user(name : String) : Nil
  # end
  # ```
  annotation QueryParam; end

  # Apply a *prefix* to all actions within `self`.
  #
  # ## Example
  # ```
  # @[ART::Prefix("calendar")] # It can also use a named argument `@[ART::Prefix(prefix: "calendar")]
  # class CalendarController < ART::Controller
  #   # The route of this action would be `GET /calendar/events`
  #   @[ART::Get(path: "events")]
  #   def events : String
  #     "events"
  #   end
  # end
  # ```
  annotation Prefix; end
end
