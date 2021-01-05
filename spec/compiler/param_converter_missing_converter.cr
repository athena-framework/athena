require "../spec_helper"

class CompileController < Athena::Routing::Controller
  @[ARTA::Get(path: "/")]
  @[ARTA::ParamConverter("num")]
  def action(num : Int32) : Int32
    num
  end
end

ART.run
