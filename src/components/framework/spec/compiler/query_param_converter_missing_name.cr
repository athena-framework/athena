require "../spec_helper"

class CompileController < ATH::Controller
  @[ARTA::Get(path: "/")]
  @[ATHA::QueryParam("all", converter: {format: "%Y--%m//%d %T"})]
  def action(all : Bool) : Int32
    123
  end
end

ATH.run
