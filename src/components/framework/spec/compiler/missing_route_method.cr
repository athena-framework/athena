require "../spec_helper"

class CompileController < ATH::Controller
  @[ARTA::Route("/")]
  def action : Nil
  end
end

ATH.run
