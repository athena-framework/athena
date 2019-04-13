require "../../../routing_spec_helper"

class CompileController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "int8/:foo/:bar")]
  def one_action_two_path(foo : String) : Int32
    123
  end
end

Athena::Routing.run
