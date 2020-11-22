require "./scalar_param"

struct Athena::Routing::Params::RequestParam(T) < Athena::Routing::Params::ScalarParam
  define_initializer

  def parse_value(request : HTTP::Request, default = nil)
    request_data = request.request_data

    return default unless request_data.has_key? self.key

    if self.type <= Array
      request_data.fetch_all self.key
    else
      request_data[self.key]
    end
  end
end
