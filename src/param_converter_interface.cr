abstract struct Athena::Routing::ParamConverterInterface
  TAG = "athena.param_converter"

  def apply(request : HTTP::Request, configuration) : Nil; end
end
