require "../../../routing_spec_helper"

struct CompileController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "int8/:num")]
  def self.one_action_id_one_path(num_id : String) : Int32
    123
  end
end

Athena::Routing.run
