struct Athena::Routing::Parameters::QueryParameter(T) < Athena::Routing::Parameters::Parameter(T)
  def initialize(name : String, @pattern : Regex? = nil, default : T? = nil, type : T.class = T)
    super name, default, type
  end

  # :inherit:
  def extract(request : HTTP::Request) : String?
    value = request.query_params[@name]?
    if !value.nil? && (ptn = @pattern)
      raise ART::Exceptions::UnprocessableEntity.new "Expected #{parameter_type} parameter '#{@name}' to match '#{ptn}' but got '#{value}'" unless value =~ ptn
    end
    value
  end

  # :inherit:
  def parameter_type : String
    "query"
  end
end
