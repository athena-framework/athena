require "../../../routing_spec_helper"

struct CompileController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "int8/", query: {"bar" => /bar/})]
  def self.no_action_one_query : Int32
    123
  end
end

Athena::Routing.run
