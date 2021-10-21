require "../spec_helper"

@[ARTA::Prefix]
class CompileController < Athena::Framework::Controller
  @[ARTA::Get(path: "/")]
  def action : Int32
    123
  end
end

ATH.run
