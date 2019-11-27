class HTTP::Request
  # The `ART::Action` object associated with this request.
  #
  # Will only be set if a route was able to be resolved.
  property! route : ART::Action

  # A hash of path params parsed from the requests's path.
  property! path_params : Hash(String, String)
end
