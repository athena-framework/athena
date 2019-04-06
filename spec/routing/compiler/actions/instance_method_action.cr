require "../../../routing_spec_helper"

struct CompileController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "int8/")]
  def instance_method : Int32
    123
  end
end

Athena::Routing.run
