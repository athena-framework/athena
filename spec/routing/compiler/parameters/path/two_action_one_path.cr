require "../../../routing_spec_helper"

class CompileController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "int8/(:foo)")]
  def two_action_one_path(foo : String, bar : Bool) : Int32
    123
  end
end

Athena::Routing.run
