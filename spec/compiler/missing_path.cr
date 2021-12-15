require "../spec_helper"

class CompileController < Athena::Framework::Controller
  @[ATHA::Get]
  def action : Int32
    123
  end
end

ATH.run
