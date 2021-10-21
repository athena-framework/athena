require "../spec_helper"

class TestController < ATH::Controller
  @[ATHA::Get(path: "user/:id")]
  def action1(id : Int64) : Int64
    id
  end
end

class OtherController < ATH::Controller
  @[ATHA::Get(path: "user/:user_id")]
  def action2(user_id : Int64) : Int64
    user_id
  end
end

ATH.run
