struct AthenaController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "noParamsGet")]
  def self.no_params_get : String
    "foobar"
  end

  @[Athena::Routing::Get(path: "/posts/(:page)")]
  def self.default_value(page : Int32 = 99) : Int32
    page.should be_a Int32
    [123, 99].should contain page
    page
  end

  @[Athena::Routing::Get(path: "/posts/:value/bvar")]
  def self.same_path(value : String) : String
    value.should be_a String
    value.should eq "foo"
    value
  end

  @[Athena::Routing::Post(path: "/posts/(:page)")]
  def self.default_value_post(page : Int32, body : Int32? = 1) : Int32?
    page.should be_a Int32
    page.should eq 99
    if b = body
      [1, 100].should contain b
    end
    if b = body
      page + b
    end
  end

  @[Athena::Routing::Get(path: "double/:val1/:val2")]
  def self.double_params(val1 : Int32, val2 : Int32) : Int32
    val1.should be_a Int32
    val2.should be_a Int32
    val1.should eq 1000
    val2.should eq 9000
    val1 + val2
  end

  @[Athena::Routing::Get(path: "get/constraints/:time", constraints: {"time" => /\d:\d:\d/})]
  def self.route_constraints(time : String) : String
    time
  end

  @[Athena::Routing::Post(path: "noParamsPostRequired")]
  def self.no_params_post_required(body : String) : String
    "foobar"
  end

  @[Athena::Routing::Post(path: "noParamsPostOptional")]
  def self.no_params_post_optional(body : String?) : String
    "foobar"
  end

  @[Athena::Routing::Post(path: "double/:val1")]
  def self.double_params_post(body : Int32, val1 : Int32) : Int32
    val1.should be_a Int32
    body.should be_a Int32
    val1.should eq 750
    body.should eq 250
    val1 + body
  end

  @[Athena::Routing::Get(path: "ecr_html")]
  @[Athena::Routing::View(renderer: Athena::Routing::Renderers::ECRRenderer)]
  def self.ecr_html : String
    # ameba:disable Lint/UselessAssign
    name = "John"
    ECR.render "spec/routing/greeting.ecr"
  end

  @[Athena::Routing::Get(path: "get/query_param_constraint_required", query: {"time" => /\d:\d:\d/})]
  def self.query_param_constraint_required(time : String) : String
    time
  end

  @[Athena::Routing::Get(path: "get/query_param_required", query: {"time" => nil})]
  def self.query_param_required(time : String) : String
    time
  end

  @[Athena::Routing::Get(path: "get/query_params_constraint_optional", query: {"time" => /\d:\d:\d/})]
  def self.query_param_optional_constraint(time : String?) : String?
    time
  end

  @[Athena::Routing::Get(path: "get/query_params_constraint_optional_default", query: {"time" => /\d:\d:\d/})]
  def self.query_param_optional_constraint_default(time : String? = "foo") : String?
    time
  end

  @[Athena::Routing::Get(path: "get/query_params_optional", query: {"time" => nil})]
  def self.query_param_optional(time : String?) : String?
    time
  end

  @[Athena::Routing::Get(path: "get/query_params_optional_default", query: {"page" => nil})]
  def self.query_param_optional_default(page : Int32? = 999) : Int32?
    page
  end

  @[Athena::Routing::Get(path: "get/custom_error")]
  def self.custom_error : Nil
    raise Athena::Routing::Exceptions::ImATeapotException.new "teapot"
  end

  @[Athena::Routing::Get(path: "get/class/response")]
  def self.response : Nil
    get_response.headers.add "Foo", "Bar"
  end

  @[Athena::Routing::Get(path: "get/class/request")]
  def self.request : String
    get_request.path
  end
end
