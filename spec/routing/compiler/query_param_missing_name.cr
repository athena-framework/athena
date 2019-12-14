require "../routing_spec_helper"

struct CompileController < Athena::Routing::Controller
  @[ART::Get(path: "/")]
  @[ART::QueryParam]
  def action(all : Bool) : Int32
    123
  end
end

ART.run
