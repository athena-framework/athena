class AthenaController < Athena::Routing::ClassController
  @[Athena::Routing::Get(path: "noParamsGet")]
  def self.no_params_get : String
    "foobar"
  end

  @[Athena::Routing::Get(path: "/posts/(:page)")]
  def self.default_value(page : Int32 = 99) : Int32
    it "should run correctly" do
      page.should be_a Int32
      [123, 99].should contain page
    end
    page
  end

  @[Athena::Routing::Get(path: "/posts/:value/bvar")]
  def self.same_path(value : String) : String
    it "should run correctly" do
      value.should be_a String
      value.should eq "foo"
    end
    value
  end

  @[Athena::Routing::Post(path: "/posts/:page")]
  def self.default_value_post(page : Int32, body : Int32 = 1) : Int32
    it "should run correctly" do
      page.should be_a Int32
      page.should eq 99
      [1, 100].should contain body
    end
    page + body
  end

  @[Athena::Routing::Get(path: "double/:val1/:val2")]
  def self.double_params(val1 : Int32, val2 : Int32) : Int32
    it "should run correctly" do
      val1.should be_a Int32
      val2.should be_a Int32
      val1.should eq 1000
      val2.should eq 9000
    end
    val1 + val2
  end

  @[Athena::Routing::Get(path: "get/constraints/:time", constraints: {"time" => /\d:\d:\d/})]
  def self.route_constraints(time : String) : String
    time
  end

  @[Athena::Routing::Post(path: "noParamsPost")]
  def self.no_params_post : String
    "foobar"
  end

  @[Athena::Routing::Post(path: "double/:val")]
  def self.double_params_post(val1 : Int32, val2 : Int32) : Int32
    it "should run correctly" do
      val1.should be_a Int32
      val2.should be_a Int32
      val1.should eq 750
      val2.should eq 250
    end
    val1 + val2
  end
end
