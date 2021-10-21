require "./scalar_param"

# Represents a request's query parameter.  See `ARTA::QueryParam`.
struct Athena::Framework::Params::QueryParam(T) < Athena::Framework::Params::ScalarParam
  # This is included here because of https://github.com/crystal-lang/crystal/issues/7584
  include Athena::Framework::Params::ParamInterface

  define_initializer

  # :inherit:
  def extract_value(request : ATH::Request, default : _ = nil)
    query_params = request.query_params

    return default unless query_params.has_key? self.key

    if self.type <= Array
      query_params.fetch_all self.key
    else
      query_params[self.key]
    end
  end
end
