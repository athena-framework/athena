require "../spec_helper"

class CompileController < ART::Controller
  @[ART::Route("/")]
  def action : Nil
  end
end

ART.run
