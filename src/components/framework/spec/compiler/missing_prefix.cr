require "../spec_helper"

@[ATHA::Prefix]
class CompileController < Athena::Framework::Controller
  @[ATHA::Get(path: "/")]
  def action : Int32
    123
  end
end

ATH.run
