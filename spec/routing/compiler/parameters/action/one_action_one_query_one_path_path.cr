require "../../../routing_spec_helper"

struct CompileController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "int8/:bar", query: {"foo" => /bar/})]
  def one_action_one_query_one_path_path(foo : String) : Int32
    123
  end
end

Athena::Routing.run
