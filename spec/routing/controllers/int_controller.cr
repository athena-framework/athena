class IntController < Athena::Routing::ClassController
  @[Athena::Routing::Get(path: "int8/:num")]
  def self.int8(num : Int8) : Int8
    it "should run correctly" do
      num.should be_a Int8
      num.should eq 123
    end
    num
  end

  @[Athena::Routing::Post(path: "int8")]
  def self.int8_post(body : Int8) : Int8
    it "should run correctly" do
      body.should be_a Int8
      body.should eq 123
    end
    body
  end

  @[Athena::Routing::Get(path: "int16/:num")]
  def self.int16(num : Int16) : Int16
    it "should run correctly" do
      num.should be_a Int16
      num.should eq 456
    end
    num
  end

  @[Athena::Routing::Post(path: "int16/")]
  def self.int16_post(body : Int16) : Int16
    it "should run correctly" do
      body.should be_a Int16
      body.should eq 456
    end
    body
  end

  @[Athena::Routing::Get(path: "int32/:num")]
  def self.int32(num : Int32) : Int32
    it "should run correctly" do
      num.should be_a Int32
      num.should eq 111111
    end
    num
  end

  @[Athena::Routing::Post(path: "int32")]
  def self.int32_post(body : Int32) : Int32
    it "should run correctly" do
      body.should be_a Int32
      body.should eq 111111
    end
    body
  end

  @[Athena::Routing::Get(path: "int64/:num")]
  def self.int64(num : Int64) : Int64
    it "should run correctly" do
      num.should be_a Int64
      num.should eq 9999999999999999
    end
    num
  end

  @[Athena::Routing::Post(path: "int64")]
  def self.int64_post(body : Int64) : Int64
    it "should run correctly" do
      body.should be_a Int64
      body.should eq 9999999999999999
    end
    body
  end

  # @[Athena::Routing::Get(path: "int128/:num")]
  # def self.int128(num : Int128) : Int128
  #   it "should run correctly" do
  #     num.should be_a Int128
  #     num.should eq 9999999999999999
  #   end
  #   num
  # end

  # @[Athena::Routing::Post(path: "int128/:num")]
  # def self.int128_post(num : Int128) : Int128
  #   it "should run correctly" do
  #     num.should be_a Int128
  #     num.should eq 9999999999999999
  #   end
  #   num
  # end

  @[Athena::Routing::Get(path: "uint8/:num")]
  def self.uint8(num : UInt8) : UInt8
    it "should run correctly" do
      num.should be_a UInt8
      num.should eq 123
    end
    num
  end

  @[Athena::Routing::Post(path: "uint8/")]
  def self.uint8_post(body : UInt8) : UInt8
    it "should run correctly" do
      body.should be_a UInt8
      body.should eq 123
    end
    body
  end

  @[Athena::Routing::Get(path: "uint16/:num")]
  def self.uint16(num : UInt16) : UInt16
    it "should run correctly" do
      num.should be_a UInt16
      num.should eq 456
    end
    num
  end

  @[Athena::Routing::Post(path: "uint16")]
  def self.uint1_post(body : UInt16) : UInt16
    it "should run correctly" do
      body.should be_a UInt16
      body.should eq 456
    end
    body
  end

  @[Athena::Routing::Get(path: "uint32/:num")]
  def self.uint32(num : UInt32) : UInt32
    it "should run correctly" do
      num.should be_a UInt32
      num.should eq 111111
    end
    num
  end

  @[Athena::Routing::Post(path: "uint32")]
  def self.uint32_post(body : UInt32) : UInt32
    it "should run correctly" do
      body.should be_a UInt32
      body.should eq 111111
    end
    body
  end

  @[Athena::Routing::Get(path: "uint64/:num")]
  def self.uint64(num : UInt64) : UInt64
    it "should run correctly" do
      num.should be_a UInt64
      num.should eq 9999999999999999
    end
    num
  end

  @[Athena::Routing::Post(path: "uint64/")]
  def self.uint64_post(body : UInt64) : UInt64
    it "should run correctly" do
      body.should be_a UInt64
      body.should eq 9999999999999999
    end
    body
  end

  # @[Athena::Routing::Get(path: "uint128/:num")]
  # def self.uint128(num : UInt128) : UInt128
  #   it "should run correctly" do
  #     num.should be_a UInt128
  #     num.should eq 9999999999999999
  #   end
  #   num
  # end

  # @[Athena::Routing::Post(path: "uint128")]
  # def self.uint128_post(num : UInt128) : UInt128
  #   it "should run correctly" do
  #     num.should be_a UInt128
  #     num.should eq 9999999999999999
  #   end
  #   num
  # end
end
