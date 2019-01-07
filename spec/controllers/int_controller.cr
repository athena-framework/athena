class IntController < Athena::ClassController
  @[Athena::Get(path: "int8/:num")]
  def self.int8(num : Int8) : Int8
    it "should run correctly" do
      num.should be_a Int8
      num.should eq 123
    end
    num
  end

  @[Athena::Post(path: "int8")]
  def self.int8_post(num : Int8) : Int8
    it "should run correctly" do
      num.should be_a Int8
      num.should eq 123
    end
    num
  end

  @[Athena::Get(path: "int16/:num")]
  def self.int16(num : Int16) : Int16
    it "should run correctly" do
      num.should be_a Int16
      num.should eq 456
    end
    num
  end

  @[Athena::Post(path: "int16/")]
  def self.int16_post(num : Int16) : Int16
    it "should run correctly" do
      num.should be_a Int16
      num.should eq 456
    end
    num
  end

  @[Athena::Get(path: "int32/:num")]
  def self.int32(num : Int32) : Int32
    it "should run correctly" do
      num.should be_a Int32
      num.should eq 111111
    end
    num
  end

  @[Athena::Post(path: "int32")]
  def self.int32_post(num : Int32) : Int32
    it "should run correctly" do
      num.should be_a Int32
      num.should eq 111111
    end
    num
  end

  @[Athena::Get(path: "int64/:num")]
  def self.int64(num : Int64) : Int64
    it "should run correctly" do
      num.should be_a Int64
      num.should eq 9999999999999999
    end
    num
  end

  @[Athena::Post(path: "int64")]
  def self.int64_post(num : Int64) : Int64
    it "should run correctly" do
      num.should be_a Int64
      num.should eq 9999999999999999
    end
    num
  end

  # @[Athena::Get(path: "int128/:num")]
  # def self.int128(num : Int128) : Int128
  #   it "should run correctly" do
  #     num.should be_a Int128
  #     num.should eq 9999999999999999
  #   end
  #   num
  # end

  # @[Athena::Post(path: "int128/:num")]
  # def self.int128_post(num : Int128) : Int128
  #   it "should run correctly" do
  #     num.should be_a Int128
  #     num.should eq 9999999999999999
  #   end
  #   num
  # end

  @[Athena::Get(path: "uint8/:num")]
  def self.uint8(num : UInt8) : UInt8
    it "should run correctly" do
      num.should be_a UInt8
      num.should eq 123
    end
    num
  end

  @[Athena::Post(path: "uint8/")]
  def self.uint8_post(num : UInt8) : UInt8
    it "should run correctly" do
      num.should be_a UInt8
      num.should eq 123
    end
    num
  end

  @[Athena::Get(path: "uint16/:num")]
  def self.uint16(num : UInt16) : UInt16
    it "should run correctly" do
      num.should be_a UInt16
      num.should eq 456
    end
    num
  end

  @[Athena::Post(path: "uint16")]
  def self.uint1_post(num : UInt16) : UInt16
    it "should run correctly" do
      num.should be_a UInt16
      num.should eq 456
    end
    num
  end

  @[Athena::Get(path: "uint32/:num")]
  def self.uint32(num : UInt32) : UInt32
    it "should run correctly" do
      num.should be_a UInt32
      num.should eq 111111
    end
    num
  end

  @[Athena::Post(path: "uint32")]
  def self.uint32_post(num : UInt32) : UInt32
    it "should run correctly" do
      num.should be_a UInt32
      num.should eq 111111
    end
    num
  end

  @[Athena::Get(path: "uint64/:num")]
  def self.uint64(num : UInt64) : UInt64
    it "should run correctly" do
      num.should be_a UInt64
      num.should eq 9999999999999999
    end
    num
  end

  @[Athena::Post(path: "uint64/")]
  def self.uint64_post(num : UInt64) : UInt64
    it "should run correctly" do
      num.should be_a UInt64
      num.should eq 9999999999999999
    end
    num
  end

  # @[Athena::Get(path: "uint128/:num")]
  # def self.uint128(num : UInt128) : UInt128
  #   it "should run correctly" do
  #     num.should be_a UInt128
  #     num.should eq 9999999999999999
  #   end
  #   num
  # end

  # @[Athena::Post(path: "uint128")]
  # def self.uint128_post(num : UInt128) : UInt128
  #   it "should run correctly" do
  #     num.should be_a UInt128
  #     num.should eq 9999999999999999
  #   end
  #   num
  # end
end
