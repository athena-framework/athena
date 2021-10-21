require "../spec_helper"

class CompileController < Athena::Framework::Controller
  @[ARTA::Get(path: "/:id")]
  def action(id) : Int32
    123
  end
end

ATH.run
