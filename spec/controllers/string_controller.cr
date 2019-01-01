class StringController < Athena::ClassController
  @[Athena::Get(path: "string/:val")]
  def self.string(val : String) : String
    it "should run correctly" do
      val.should be_a String
      val.should eq "sdfsd"
    end
    val
  end

  @[Athena::Post(path: "string")]
  def self.string_post(val : String) : String
    it "should run correctly" do
      val.should be_a String
      val.should eq "sdfsd"
    end
    val
  end
end
