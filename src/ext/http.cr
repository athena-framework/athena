# :nodoc:
class HTTP::Request
  # The `ART::Action` object associated with this request.
  #
  # Will only be set if a route was able to be resolved.
  property! action : ART::ActionBase

  # See `ART::ParameterBag`.
  getter attributes : ART::ParameterBag = ART::ParameterBag.new

  @request_data : HTTP::Params?

  def request_data
    @request_data ||= self.parse_request_data
  end

  def safe? : Bool
    @method.in? "GET", "HEAD", "OPTIONS", "TRACE"
  end

  private def parse_request_data : HTTP::Params
    HTTP::Params.parse self.body.try(&.gets_to_end) || ""
  end
end

# :nodoc:
struct HTTP::Headers
  @cache_control : Hash(String, String | Bool) = Hash(String, String | Bool).new

  def add_cache_control_directive(key : String, value : String | Bool = true)
    @cache_control[key] = value == true ? value : value.to_s
    self.["cache-control"] = self.cache_control_header
  end

  def has_cache_control_directive(key : String) : Bool
    @cache_control.has_key? key
  end

  def get_cache_control_directive(key : String) : String | Bool | Nil
    @cache_control[key]?
  end

  def remove_cache_control_directive(key : String) : Nil
    @cache_control.delete key
    self.["cache-control"] = self.cache_control_header
  end

  private def cache_control_header : String
    @cache_control.join(", ") do |k, v|
      if true == v
        k
      else
        "#{k}=#{HTTP.quote_string v.as(String)}"
      end
    end
  end
end
