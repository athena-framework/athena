require "../../../routing_spec_helper"

class NoFind
end

class CompileController < Athena::Routing::Controller
  @[Athena::Routing::Post(path: "/")]
  @[Athena::Routing::ParamConverter(param: "body", type: NoFind, pk_type: Int64, converter: Exists)]
  def no_find(body : NoFind) : Int32
    123
  end
end

Athena::Routing.run
