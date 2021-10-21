require "../spec_helper"

class CompileController < Athena::Framework::Controller
  @[ARTA::Get(path: "/")]
  @[ARTA::ParamConverter("foo")]
  def action(num : Int32) : Int32
    num
  end
end

ATH.run
