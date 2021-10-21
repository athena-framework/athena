require "../spec_helper"

class CompileController < ATH::Controller
  @[ARTA::Get("/")]
  @[ARTA::QueryParam("page", strict: false)]
  def action(page : Int32) : Int32
    page
  end
end

ATH.run
