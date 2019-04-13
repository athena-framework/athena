require "../../../routing_spec_helper"

class NoType
end

class CompileController < Athena::Routing::Controller
  @[Athena::Routing::Post(path: "/")]
  @[Athena::Routing::ParamConverter(param: "body", converter: Exists)]
  def no_type(body : NoType) : Int32
    123
  end
end

Athena::Routing.run
