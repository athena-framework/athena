require "../spec_helper"

class CompileController < ART::Controller
  @[ARTA::Route("/")]
  def action : Nil
  end
end

ART.run
