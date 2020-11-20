require "./scalar_param"

struct Athena::Routing::Params::QueryParam(T) < Athena::Routing::Params::ScalarParam(T)
  def parse_value(request : HTTP::Request, default = nil)
    request.query_params.fetch self.key, default
  end
end
