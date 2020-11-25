require "../spec_helper"

class CompileController < ART::Controller
  @[ART::Get(path: "/")]
  @[ART::QueryParam("all", requirements: [@[Assert::NotBlank], @[ART::Get]])]
  def action(all : Bool) : Int32
    123
  end
end

ART.run
