# Contains all the `Athena::Routing` based annotations.
# See `ARTA::Route` for more information.
#
# NOTE: These are primarily to define a common type/documentation to use in custom implementations.
# As of now, they are not leveraged internally, but a future iteration could provide a built in way to resolve them into an `ART::RouteCollection`.
module Athena::Routing::Annotations
  # Same as `ARTA::Route`, but only matches the `DELETE` method.
  annotation Delete; end

  # Same as `ARTA::Route`, but only matches the `GET` method.
  annotation Get; end

  # Same as `ARTA::Route`, but only matches the `HEAD` method.
  annotation Head; end

  # Same as `ARTA::Route`, but only matches the `LINK` method.
  annotation Link; end

  # Same as `ARTA::Route`, but only matches the `PATCH` method.
  annotation Patch; end

  # Same as `ARTA::Route`, but only matches the `POST` method.
  annotation Post; end

  # Same as `ARTA::Route`, but only matches the `PUT` method.
  annotation Put; end

  # Annotation representation of an `ART::Route`.
  # Most commonly this will be applied to a method to define it as the controller for the related route,
  # but could also be applied to a controller class to apply defaults to all other `ARTA::Route` within it.
  # Custom implementations may support alternate APIs.
  # See `ART::Route` for more information.
  #
  # ## Configuration
  #
  # Various fields can be used within this annotation to control how the route is created.
  # All fields are optional unless otherwise noted.
  #
  # WARNING: Not all fields may be supported by the underlying implementation.
  #
  # #### path
  #
  # **Type:** `String | Hash(String, String)` - **required**
  #
  # The path of the route.
  #
  # #### name
  #
  # **Type:** `String`
  #
  # The unique name of the route. If not provided, a unique name should be created automatically.
  #
  # #### requirements
  #
  # **Type:** `Hash(String, String | Regex)`
  #
  # A `Hash` of patterns that each parameter must match in order for the route to match.
  #
  # #### defaults
  #
  # **Type:** `Hash(String, _)`
  #
  # The values that should be applied to the route parameters if they were not supplied within the request.
  #
  # #### host
  #
  # **Type:** `String | Regex`
  #
  # Require the [host](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Host) header to match this value in order for the route to match.
  #
  # #### methods
  #
  # **Type:** `String | Enumerable(String)`
  #
  # A whitelist of the HTTP methods this route supports.
  #
  # #### schemes
  #
  # **Type:** `String | Enumerable(String)`
  #
  # A whitelist of the HTTP schemes this route supports.
  #
  # #### condition
  #
  # **Type:** `ART::Route::Condition`
  #
  # A callback used to dynamically determine if the request matches the route.
  #
  # #### priority
  #
  # **Type:** `Int32`
  #
  # A value used to control the order the routes are registered in.
  # A higher value means that route will be registered earlier.
  #
  # #### locale
  #
  # **Type:** `String`
  #
  # Allows setting the locale this route supports.
  # Sets the special `_locale` route parameter.
  #
  # #### format
  #
  # **Type:** `String`
  #
  # Allows setting the format this route supports.
  # Sets the special `_format` route parameter.
  #
  # #### stateless
  #
  # **Type:** `Bool`
  #
  # If the route should be cached or not.
  annotation Route; end

  # Same as `ARTA::Route`, but only matches the `UNLINK` method.
  annotation Unlink; end
end
