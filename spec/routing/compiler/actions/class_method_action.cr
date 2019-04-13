require "../../../routing_spec_helper"

class CompileController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "int8/")]
  def self.class_method : Int32
    123
  end
end

Athena::Routing.run
