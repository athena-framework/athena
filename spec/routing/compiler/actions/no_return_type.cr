require "../../../routing_spec_helper"

class CompileController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "int8/")]
  def no_return_type
    123
  end
end

Athena::Routing.run