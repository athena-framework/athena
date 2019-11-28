require "../../routing_spec_helper"

abstract struct ParentController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "int8/")]
  def parent_method : Int32
    123
  end
end

abstract struct ChildController < ParentController
  @[Athena::Routing::Get(path: "int8/")]
  def child_method : Int32
    456
  end
end

Athena::Routing.run
