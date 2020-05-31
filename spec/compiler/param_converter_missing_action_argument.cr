require "../spec_helper"

class CompileController < Athena::Routing::Controller
  @[ART::Get(path: "/")]
  @[ART::ParamConverter("foo")]
  def action(num : Int32) : Int32
    num
  end
end

ART.run
