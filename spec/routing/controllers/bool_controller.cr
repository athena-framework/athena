class BoolController < Athena::Routing::ClassController
  @[Athena::Routing::Get(path: "bool/:val")]
  def self.bool(val : Bool) : Bool
    it "should run correctly" do
      val.should be_a Bool
      val.should eq true
    end
    val
  end

  @[Athena::Routing::Post(path: "bool")]
  def self.bool_post(body : Bool) : Bool
    it "should run correctly" do
      body.should be_a Bool
      body.should eq true
    end
    body
  end
end
