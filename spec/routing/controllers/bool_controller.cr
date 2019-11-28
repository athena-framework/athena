struct BoolController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "bool/:val")]
  def bool(val : Bool) : Bool
    val.should be_a Bool
    val.should eq true
    val
  end

  @[Athena::Routing::Post(path: "bool")]
  def bool_post(body : Bool) : Bool
    body.should be_a Bool
    body.should eq true
    body
  end
end
