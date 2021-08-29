require "../spec_helper"

class CompileConverter < ART::ParamConverter; end

class CompileController < Athena::Routing::Controller
  @[ARTA::Get(path: "/")]
  @[ARTA::ParamConverter("num", converter: CompileConverter)]
  def action(num : Int32) : Int32
    num
  end
end

ART.run
