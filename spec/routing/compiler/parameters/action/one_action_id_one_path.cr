require "../../../routing_spec_helper"

class CompileController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "int8/:num")]
  def one_action_id_one_path(num_id : String) : Int32
    123
  end
end

Athena::Routing.run
