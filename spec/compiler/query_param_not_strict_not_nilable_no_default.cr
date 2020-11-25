require "../spec_helper"

class CompileController < ART::Controller
  @[ART::Get("/")]
  @[ART::QueryParam("page", strict: false)]
  def action(page : Int32) : Int32
    page
  end
end

ART.run
