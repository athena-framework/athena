require "../spec_helper"

class CompileController < Athena::Framework::Controller
  @[ARTA::Get(path: "/")]
  @[ARTA::QueryParam]
  def action(all : Bool) : Int32
    123
  end
end

ATH.run
