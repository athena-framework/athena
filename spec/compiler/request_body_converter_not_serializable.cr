require "../spec_helper"

record Foo, text : String

class CompileController < Athena::Framework::Controller
  @[ARTA::Get(path: "/")]
  @[ARTA::ParamConverter("foo", converter: ATH::RequestBodyConverter)]
  def action(foo : Foo) : Foo
    foo
  end
end

ATH.run
