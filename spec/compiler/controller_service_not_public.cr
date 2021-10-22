require "../spec_helper"

@[ADI::Register]
class CompileController < ATH::Controller
  @[ATHA::Get(path: "/")]
  def action : String
    "foo"
  end
end

ATH.run
