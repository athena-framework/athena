class FloatController < Athena::ClassController
  @[Athena::Get(path: "float32/:num")]
  def self.float32(num : Float32) : Float32
    it "should run correctly" do
      num.should be_a Float32
      num.should eq -2342.223_f32
    end
    num
  end

  @[Athena::Post(path: "float32/")]
  def self.float32_post(num : Float32) : Float32
    it "should run correctly" do
      num.should be_a Float32
      num.should eq -2342.223_f32
    end
    num
  end

  @[Athena::Get(path: "float64/:num")]
  def self.float64(num : Float64) : Float64
    it "should run correctly" do
      num.should be_a Float64
      num.should eq 2342.234234234223
    end
    num
  end

  @[Athena::Post(path: "float64")]
  def self.float64_post(num : Float64) : Float64
    it "should run correctly" do
      num.should be_a Float64
      num.should eq 2342.234234234223
    end
    num
  end
end
