require "../../../routing_spec_helper"

struct CompileController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "int8/:foo", query: {"bar" => /bar/})]
  def self.one_action_one_query_one_path_query(foo : String) : Int32
    123
  end
end

Athena::Routing.run
