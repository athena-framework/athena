require "../spec_helper"

@[ADI::Register]
class CompileController < ATH::Controller
  @[ARTA::Get(path: "/")]
  def action : String
    "foo"
  end
end

ATH.run
