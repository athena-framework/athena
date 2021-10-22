require "../spec_helper"

class CompileController < Athena::Framework::Controller
  @[ATHA::Get(path: "/:id")]
  def action(id) : Int32
    123
  end
end

ATH.run
