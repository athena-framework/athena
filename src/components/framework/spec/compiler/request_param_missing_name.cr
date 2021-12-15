require "../spec_helper"

class CompileController < Athena::Framework::Controller
  @[ATHA::Get(path: "/")]
  @[ATHA::RequestParam]
  def action(all : Bool) : Int32
    123
  end
end

ATH.run
