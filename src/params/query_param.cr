require "./scalar_param"

struct Athena::Routing::Params::QueryParam(T) < Athena::Routing::Params::ScalarParam(T)
  def parse_value(request : HTTP::Request, default = nil)
    query_params = request.query_params

    return default unless query_params.has_key? self.key

    if self.type <= Array
      query_params.fetch_all self.key
    else
      query_params[self.key]
    end
  end
end
