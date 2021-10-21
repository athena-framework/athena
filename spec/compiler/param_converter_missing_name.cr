require "../spec_helper"

class CompileController < Athena::Framework::Controller
  @[ATHA::Get(path: "/")]
  @[ATHA::ParamConverter]
  def action(num : Int32) : Int32
    num
  end
end

ATH.run
