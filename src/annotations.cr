module Athena::Routing
  # Defines a GET endpoint.
  # ## Fields
  # * path : `String` - The path for the endpoint, may also be provided as the first positional argument.
  # * constraints : `Hash(String, Regex)` - A mapping between a route argument and its constraints.
  #
  # ## Examples
  # ```
  # @[Athena::Routing::Get(path: "/users/:id")]
  # def get_user : Nil
  # end
  #
  # # Or
  #
  # @[Athena::Routing::Get("/users/:id")]
  # def get_user : Nil
  # end
  # ```
  annotation Get; end

  # Defines a POST endpoint.
  # ## Fields
  # * path : `String` - The path for the endpoint, may also be provided as the first positional argument.
  # * constraints : `Hash(String, Regex)` - A mapping between a route argument and its constraints.
  #
  # ## Examples
  # ```
  # @[Athena::Routing::Post(path: "/users")]
  # def new_user : Nil
  # end
  #
  # # Or
  #
  # @[Athena::Routing::Post("/users")]
  # def new_user : Nil
  # end
  # ```
  annotation Post; end

  # Defines a PUT endpoint.
  # ## Fields
  # * path : `String` - The path for the endpoint, may also be provided as the first positional argument.
  # * constraints : `Hash(String, Regex)` - A mapping between a route argument and its constraints.
  #
  # ## Examples
  # ```
  # @[Athena::Routing::Put(path: "/users/:id")]
  # def update_user : Nil
  # end
  #
  # # Or
  #
  # @[Athena::Routing::Put("/users/:id")]
  # def update_user : Nil
  # end
  # ```
  annotation Put; end

  # Defines a PATCH endpoint.
  # ## Fields
  # * path : `String` - The path for the endpoint, may also be provided as the first positional argument.
  # * constraints : `Hash(String, Regex)` - A mapping between a route argument and its constraints.
  #
  # ## Examples
  # ```
  # @[Athena::Routing::Patch(path: "/users/:id")]
  # def partial_update_user : Nil
  # end
  #
  # # Or
  #
  # @[Athena::Routing::Patch("/users/:id")]
  # def partial_update_user : Nil
  # end
  # ```
  annotation Patch; end

  # Defines a DELETE endpoint.
  # ## Fields
  # * path : `String` - The path for the endpoint, may also be provided as the first positional argument.
  # * constraints : `Hash(String, Regex)` - A mapping between a route argument and its constraints.
  #
  # ## Examples
  # ```
  # @[Athena::Routing::Delete(path: "/users/:id")]
  # def delete_user : Nil
  # end
  #
  # # Or
  #
  # @[Athena::Routing::Delete("/users/:id")]
  # def delete_user : Nil
  # end
  # ```
  annotation Delete; end

  # Controls how params are converted.
  # ## Fields
  # * param : `String` - The param that should go through the conversion.
  #
  # ## Example
  # ```
  # @[Athena::Routing::ParamConverter(param: "user", pk_type: Int32, type: User, converter: Exists)]
  # ```
  annotation ParamConverter; end
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
