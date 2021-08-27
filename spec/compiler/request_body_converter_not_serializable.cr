require "../spec_helper"

record Foo, text : String

class CompileController < Athena::Routing::Controller
  @[ARTA::Get(path: "/")]
  @[ARTA::ParamConverter("foo", converter: ART::RequestBodyConverter)]
  def action(foo : Foo) : Foo
    foo
  end
end

ART.run
