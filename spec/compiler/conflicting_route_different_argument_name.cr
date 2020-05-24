require "../spec_helper"

class TestController < ART::Controller
  @[ART::Get(path: "user/:id")]
  def action1(id : Int64) : Int64
    id
  end
end

class OtherController < ART::Controller
  @[ART::Get(path: "user/:user_id")]
  def action2(user_id : Int64) : Int64
    user_id
  end
end

ART.run
