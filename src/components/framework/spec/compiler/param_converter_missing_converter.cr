require "../spec_helper"

class CompileController < Athena::Framework::Controller
  @[ARTA::Get(path: "/")]
  @[ATHA::ParamConverter("num")]
  def action(num : Int32) : Int32
    num
  end
end

ATH.run
