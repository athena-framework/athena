require "../spec_helper"

@[ADI::Register]
class CompileController < ART::Controller
  @[ARTA::Get(path: "/")]
  def action : String
    "foo"
  end
end

ART.run
