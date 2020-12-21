require "../spec_helper"

class CompileController < ART::Controller
  @[ARTA::Get(path: "/")]
  @[ARTA::QueryParam("all", converter: {format: "%Y--%m//%d %T"})]
  def action(all : Bool) : Int32
    123
  end
end

ART.run
