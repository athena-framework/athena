require "../spec_helper"

class CompileConverter < ATH::ParamConverter; end

class CompileController < Athena::Framework::Controller
  @[ATHA::Get(path: "/")]
  @[ATHA::ParamConverter("num", converter: CompileConverter)]
  def action(num : Int32) : Int32
    num
  end
end

ATH.run
