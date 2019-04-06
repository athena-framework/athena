require "../../../routing_spec_helper"

class NoConverter
end

struct CompileController < Athena::Routing::Controller
  @[Athena::Routing::Post(path: "/")]
  @[Athena::Routing::ParamConverter(param: "body", type: NoConverter)]
  def self.no_converter(body : NoConverter) : Int32
    123
  end
end

Athena::Routing.run
