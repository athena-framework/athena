require "./scalar_param"

struct Athena::Routing::Params::RequestParam(T) < Athena::Routing::Params::ScalarParam(T)
  def parse_value(request : HTTP::Request, default = nil)
    request.form_data.fetch self.key, default
  end
end
