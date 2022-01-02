require "../spec_helper"

class CompileController < Athena::Framework::Controller
  @[ARTA::Get(path: "/")]
  @[ATHA::RequestParam]
  def action(all : Bool) : Int32
    123
  end
end

ATH.run
