module Athena::Routing
  # :nodoc:
  @@server : HTTP::Server?

  # Defines a GET endpoint.
  # ## Fields
  # * path : `String` - The path for the endpoint.
  #
  # ## Example
  # ```
  # @[Athena::Routing::Get(path: "/users")]
  # ```
  annotation Get; end

  # Defines a POST endpoint.
  # ## Fields
  # * path : `String` - The path for the endpoint.
  #
  # ## Example
  # ```
  # @[Athena::Routing::Post(path: "/users")]
  # ```
  annotation Post; end

  # Defines a PUT endpoint.
  # ## Fields
  # * path : `String` - The path for the endpoint.
  #
  # ## Example
  # ```
  # @[Athena::Routing::Put(path: "/users")]
  # ```
  annotation Put; end

  # Defines a PATCH endpoint.
  # ## Fields
  # * path : `String` - The path for the endpoint.
  #
  # ## Example
  # ```
  # @[Athena::Routing::Patch(path: "/users")]
  # ```
  annotation Patch; end

  # Defines a DELETE endpoint.
  # ## Fields
  # * path : `String` - The path for the endpoint.
  #
  # ## Example
  # ```
  # @[Athena::Routing::Delete(path: "/users/:id")]
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
