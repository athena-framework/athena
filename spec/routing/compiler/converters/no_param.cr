require "../../../routing_spec_helper"

class NoParam
end

struct CompileController < Athena::Routing::Controller
  @[Athena::Routing::Post(path: "/")]
  @[Athena::Routing::ParamConverter(type: NoParam, converter: Exists)]
  def self.no_param(body : NoParam) : Int32
    123
  end
end

Athena::Routing.run
