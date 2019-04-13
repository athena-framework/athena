require "../../../routing_spec_helper"

class CompileController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "int8/:value")]
  def no_action_one_path : Int32
    123
  end
end

Athena::Routing.run
