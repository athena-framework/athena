require "../../../routing_spec_helper"

class CompileController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "int8/", query: {"foo" => nil, "bar" => /bar/})]
  def one_action_two_query(foo : String) : Int32
    123
  end
end

Athena::Routing.run
