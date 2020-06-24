module Athena::Routing
  # Defines a `GET` endpoint.
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

  # Defines a `POST` endpoint.
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

  # Defines a `PUT` endpoint.
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

  # Defines a `PATCH` endpoint.
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

  # Defines a `DELETE` endpoint.
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

  # Defines a `LINK` endpoint.
  #
  # ## Fields
  # * path : `String` - The path for the endpoint, may also be provided as the first positional argument.
  # * constraints : `Hash(String, Regex)` - A mapping between a route's path parameters and its constraints.
  #
  # ## Example
  # ```
  # @[ART::Link(path: "/users/:id")]
  # def link_user(id : Int32) : Nil
  # end
  # ```
  annotation Link; end

  # Applies an `ART::ParamConverterInterface` to a given argument.
  #
  # See `ART::ParamConverterInterface` for more information on defining a param converter.
  #
  # ## Fields
  #
  # * name : `String` - The name of the argument that should be converted, may also be provided as the first positional argument.
  # * converter : `ART::ParamConverterInterface.class` - The `ART::ParamConverterInterface` that should be used to convert this argument.
  #
  # ## Example
  #
  # ```
  # @[ART::Get(path: "/multiply/:num")]
  # @[ART::ParamConverter("num", converter: MultiplyConverter)]
  # def multiply(num : Int32) : Int32
  #   num
  # end
  # ```
  annotation ParamConverter; end

  # Apply a *prefix* to all actions within `self`.  Can be a static string, but may also contain path arguments.
  #
  # ## Fields
  #
  # * prefix : `String` - The path prefix to use, may also be provided as the first positional argument.
  #
  # ## Example
  #
  # ```
  # @[ART::Prefix(prefix: "calendar")]
  # class CalendarController < ART::Controller
  #   # The route of this action would be `GET /calendar/events`.
  #   @[ART::Get(path: "events")]
  #   def events : String
  #     "events"
  #   end
  # end
  # ```
  annotation Prefix; end

  # Defines a query parameter tied to a given argument.
  #
  # The type of the query param is derived from the type restriction of the associated controller action argument.
  #
  # A non-nilable type denotes it as required.  If the parameter is not supplied, and no default value is assigned, an `ART::Exceptions::BadRequest` exception is raised.
  # A nilable type denotes it as optional.  If the parameter is not supplied (or could not be converted), and no default value is assigned, it is `nil`.
  #
  # ## Fields
  #
  # * name : `String` - The name of the query parameter, may also be provided as the first positional argument.
  # * constraints : `Regex` - A pattern the query param must match to be considered valid.
  #
  # ## Example
  #
  # ```
  # @[ART::Get(path: "/example")]
  # @[ART::QueryParam("query_param")]
  # def get_user(query_param : String) : Nil
  # end
  # ```
  annotation QueryParam; end

  # Defines an endpoint with an arbitrary `HTTP` method.  Can be used for defining non-standard `HTTP` method routes.
  #
  # ## Fields
  # * path : `String` - The path for the endpoint, may also be provided as the first positional argument.
  # * method : `String` - The `HTTP` method to use for the endpoint.
  # * constraints : `Hash(String, Regex)` - A mapping between a route's path parameters and its constraints.
  #
  # ## Example
  # ```
  # @[ART::Route("/some/path", method: "TRACE")]
  # def trace_route : Nil
  # end
  # ```
  annotation Route; end

  # Defines an `UNLINK` endpoint.
  #
  # ## Fields
  # * path : `String` - The path for the endpoint, may also be provided as the first positional argument.
  # * constraints : `Hash(String, Regex)` - A mapping between a route's path parameters and its constraints.
  #
  # ## Example
  # ```
  # @[ART::Unlink(path: "/users/:id")]
  # def unlink_user(id : Int32) : Nil
  # end
  # ```
  annotation Unlink; end
end
