require "../spec_helper"

class CompileController < ATH::Controller
  @[ATHA::Route("/")]
  def action : Nil
  end
end

ATH.run
