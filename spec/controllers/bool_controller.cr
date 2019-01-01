class BoolController < Athena::ClassController
  @[Athena::Get(path: "bool/:val")]
  def self.bool(val : Bool) : Bool
    it "should run correctly" do
      val.should be_a Bool
      val.should eq true
    end
    val
  end

  @[Athena::Post(path: "bool")]
  def self.bool_post(val : Bool) : Bool
    it "should run correctly" do
      val.should be_a Bool
      val.should eq true
    end
    val
  end
end
