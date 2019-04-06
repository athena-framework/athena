require "../../../routing_spec_helper"

struct CompileController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "int8/", query: {"num" => /\d+/})]
  def self.one_action_id_one_query(num_id : String) : Int32
    123
  end
end

Athena::Routing.run
