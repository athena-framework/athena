require "./scalar_param"

# Represents form data with a request's body.  See `ART::RequestParam`.
struct Athena::Routing::Params::RequestParam(T) < Athena::Routing::Params::ScalarParam
  define_initializer

  # :inherit:
  def extract_value(request : HTTP::Request, default : _ = nil)
    request_data = request.request_data

    return default unless request_data.has_key? self.key

    if self.type <= Array
      request_data.fetch_all self.key
    else
      request_data[self.key]
    end
  end
end
