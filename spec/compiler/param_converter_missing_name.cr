require "../spec_helper"

class CompileController < Athena::Routing::Controller
  @[ART::Get(path: "/")]
  @[ART::ParamConverter]
  def action(num : Int32) : Int32
    num
  end
end

ART.run
