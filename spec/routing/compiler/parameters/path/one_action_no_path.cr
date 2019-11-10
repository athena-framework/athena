require "../../../routing_spec_helper"

struct CompileController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "int8/")]
  def one_action_no_path(foo : String) : Int32
    123
  end
end

Athena::Routing.run
