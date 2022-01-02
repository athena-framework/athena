require "../spec_helper"

class CompileController < ATH::Controller
  @[ARTA::Get(path: "/")]
  @[ATHA::QueryParam("all", requirements: [@[Assert::NotBlank], 1])]
  def action(all : Bool) : Int32
    123
  end
end

ATH.run
