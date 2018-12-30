struct SController < Athena::StructController
  @[Athena::Get(path: "struct/:val")]
  def self.doWork(val : Int32) : Int32
    it "should run correctly" do
      val.should be_a Int32
      val.should eq 123
    end
    -val
  end

  @[Athena::Post(path: "struct")]
  def self.doWorkPost(val : Int32) : Int32
    it "should run correctly" do
      val.should be_a Int32
      val.should eq 123
    end
    -val
  end
end
