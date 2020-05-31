require "../spec_helper"

@[ADI::Register]
class CompileController < ART::Controller
  @[ART::Get(path: "/")]
  def action : String
    "foo"
  end
end

ART.run
