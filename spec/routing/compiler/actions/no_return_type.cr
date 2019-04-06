require "../../../routing_spec_helper"

struct CompileController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "int8/")]
  def self.no_return_type
    123
  end
end

Athena::Routing.run
