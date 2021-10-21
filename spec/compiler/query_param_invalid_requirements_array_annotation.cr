require "../spec_helper"

class CompileController < ATH::Controller
  @[ARTA::Get(path: "/")]
  @[ARTA::QueryParam("all", requirements: [@[Assert::NotBlank], @[ARTA::Get]])]
  def action(all : Bool) : Int32
    123
  end
end

ATH.run
