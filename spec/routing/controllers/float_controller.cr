class FloatController < Athena::Routing::ClassController
  @[Athena::Routing::Get(path: "float32/:num")]
  def self.float32(num : Float32) : Float32
    it "should run correctly" do
      num.should be_a Float32
      num.should eq -2342.223_f32
    end
    num
  end

  @[Athena::Routing::Post(path: "float32/")]
  def self.float32_post(body : Float32) : Float32
    it "should run correctly" do
      body.should be_a Float32
      body.should eq -2342.223_f32
    end
    body
  end

  @[Athena::Routing::Get(path: "float64/:num")]
  def self.float64(num : Float64) : Float64
    it "should run correctly" do
      num.should be_a Float64
      num.should eq 2342.234234234223
    end
    num
  end

  @[Athena::Routing::Post(path: "float64")]
  def self.float64_post(body : Float64) : Float64
    it "should run correctly" do
      body.should be_a Float64
      body.should eq 2342.234234234223
    end
    body
  end
end
