require "../spec_helper"

class TestController < ATH::Controller
  @[ARTA::Get(path: "some/path/:id")]
  def action1(id : Int64) : Int64
    id
  end
end

class OtherController < ATH::Controller
  @[ARTA::Get(path: "some/path/:id")]
  def action2(id : Int64) : Int64
    id
  end
end

ATH.run
