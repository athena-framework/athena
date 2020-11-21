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

  private def parse_request_data : HTTP::Params
    HTTP::Params.parse self.body.try(&.gets_to_end) || ""
  end
end
