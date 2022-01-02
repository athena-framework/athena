require "../spec_helper"

class CompileController < Athena::Framework::Controller
  @[ARTA::Get]
  def action : Int32
    123
  end
end

ATH.run
