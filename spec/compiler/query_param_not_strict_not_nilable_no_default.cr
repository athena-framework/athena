require "../spec_helper"

class CompileController < ART::Controller
  @[ARTA::Get("/")]
  @[ARTA::QueryParam("page", strict: false)]
  def action(page : Int32) : Int32
    page
  end
end

ART.run
