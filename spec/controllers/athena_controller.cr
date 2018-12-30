class AthenaController < Athena::ClassController
  @[Athena::Get(path: "noParamsGet")]
  def self.noParamsGet : String
    "foobar"
  end

  @[Athena::Get(path: "/posts/(:page)")]
  def self.defaultValue(page : Int32 = 99) : Int32
    it "should run correctly" do
      page.should be_a Int32
      [123, 99].should contain page
    end
    page
  end

  @[Athena::Get(path: "/posts/:value/bvar")]
  def self.samePath(value : String) : String
    it "should run correctly" do
      value.should be_a String
      value.should eq "foo"
    end
    value
  end

  @[Athena::Post(path: "/posts/:page")]
  def self.defaultValuePost(page : Int32, body : Int32 = 1) : Int32
    it "should run correctly" do
      page.should be_a Int32
      page.should eq 99
      [1, 100].should contain body
    end
    page + body
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
