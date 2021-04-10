struct HTTP::Headers
  # A Hash representing the current [cache-control](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control) header directives.
  @cache_control : Hash(String, String | Bool) = Hash(String, String | Bool).new

  # Adds the provided *directive*; updating the `cache-control` header.
  def add_cache_control_directive(directive : String, value : String | Bool = true)
    @cache_control[directive] = value == true ? value : value.to_s
    self.["cache-control"] = self.cache_control_header
  end

  # Returns `true` if the current `cache-control` header has the provided *directive*.
  # Otherwise returns `false`.
  def has_cache_control_directive?(directive : String) : Bool
    @cache_control.has_key? directive
  end

  # Removes the provided *directive* from the `cache-control` header, or `nil` if it is not set.
  def get_cache_control_directive(directive : String) : String | Bool | Nil
    @cache_control[directive]?
  end

  # Removes the provided *directive* from the `cache-control` header.
  def remove_cache_control_directive(directive : String) : Nil
    @cache_control.delete directive
    self.["cache-control"] = self.cache_control_header
  end

  private def cache_control_header : String
    ART::HeaderUtils.to_string @cache_control, ", "
  end
end
