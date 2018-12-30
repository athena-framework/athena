class AthenaController < Athena::ClassController
  @[Athena::Get(path: "noParamsGet")]
  def self.noParamsGet : String
    "foobar"
  end

  @[Athena::Get(path: "double/:val1/:val2")]
  def self.doubleParams(val1 : Int32, val2 : Int32) : Int32
    it "should run correctly" do
      val1.should be_a Int32
      val2.should be_a Int32
      val1.should eq 1000
      val2.should eq 9000
    end
    val1 + val2
  end

  @[Athena::Post(path: "noParamsPost")]
  def self.noParamsPost : String
    "foobar"
  end

  @[Athena::Post(path: "double/:val")]
  def self.doubleParamsPost(val1 : Int32, val2 : Int32) : Int32
    it "should run correctly" do
      val1.should be_a Int32
      val2.should be_a Int32
      val1.should eq 750
      val2.should eq 250
    end
    val1 + val2
  end
end
