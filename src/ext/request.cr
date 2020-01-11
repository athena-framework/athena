class HTTP::Request
  # The `ART::Action` object associated with this request.
  #
  # Will only be set if a route was able to be resolved.
  property! route : ART::Action

  # A hash of path params parsed from the requests's path.
  property! path_params : Hash(String, String)

  # Allows storing simple values within the context of a request.
  property attributes = Hash(String, Bool | Int32 | String | Float64 | Nil).new
end
