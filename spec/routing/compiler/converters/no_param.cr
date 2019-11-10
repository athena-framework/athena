require "../../routing_spec_helper"

struct NoParam
end

struct CompileController < Athena::Routing::Controller
  @[Athena::Routing::Post(path: "/")]
  @[Athena::Routing::ParamConverter(type: NoParam, converter: Exists)]
  def no_param(body : NoParam) : Int32
    123
  end
end

Athena::Routing.run
