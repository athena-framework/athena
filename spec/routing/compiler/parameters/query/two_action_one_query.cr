require "../../../routing_spec_helper"

struct CompileController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "int8/", query: {"foo" => nil})]
  def self.two_action_one_query(foo : String, bar : Bool) : Int32
    123
  end
end

Athena::Routing.run
