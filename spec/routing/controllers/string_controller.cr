class StringController < Athena::Routing::ClassController
  @[Athena::Routing::Get(path: "string/:val")]
  def self.string(val : String) : String
    it "should run correctly" do
      val.should be_a String
      val.should eq "sdfsd"
    end
    val
  end

  @[Athena::Routing::Post(path: "string")]
  def self.string_post(val : String) : String
    it "should run correctly" do
      val.should be_a String
      val.should eq "sdfsd"
    end
    val
  end
end
