require "./scalar_param"

# Represents a request's query parameter.  See `ART::QueryParam`.
struct Athena::Routing::Params::QueryParam(T) < Athena::Routing::Params::ScalarParam
  define_initializer

  # :inherit:
  def extract_value(request : HTTP::Request, default : _ = nil)
    query_params = request.query_params

    return default unless query_params.has_key? self.key

    if self.type <= Array
      query_params.fetch_all self.key
    else
      query_params[self.key]
    end
  end
end
