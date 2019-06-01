class AthenaController < Athena::Routing::Controller
  include Athena::DI::Injectable

  def initialize(@request_stack : Athena::Routing::RequestStack); end

  @[Athena::Routing::Get(path: "noParamsGet")]
  def no_params_get : String
    "foobar"
  end

  @[Athena::Routing::Get(path: "/posts/(:page)")]
  def default_value(page : Int32 = 99) : Int32
    page.should be_a Int32
    [123, 99].should contain page
    page
  end

  @[Athena::Routing::Get(path: "/posts/:value/bvar")]
  def same_path(value : String) : String
    value.should be_a String
    value.should eq "foo"
    value
  end

  @[Athena::Routing::Post(path: "/posts/(:page)")]
  def default_value_post(page : Int32, body : Int32? = 1) : Int32?
    page.should be_a Int32
    page.should eq 99
    if b = body
      [1, 100].should contain b
    end
    if b = body
      page + b
    end
  end

  @[Athena::Routing::Get(path: "get/safe")]
  def safe_request_check : String
    initial_query = @request_stack.request.query
    sleep 2 if initial_query == "foo"
    check_query = @request_stack.request.query

    initial_query == check_query ? "safe" : "unsafe"
  end

  @[Athena::Routing::Get(path: "double/:val1/:val2")]
  def double_params(val1 : Int32, val2 : Int32) : Int32
    val1.should be_a Int32
    val2.should be_a Int32
    val1.should eq 1000
    val2.should eq 9000
    val1 + val2
  end

  @[Athena::Routing::Get(path: "get/constraints/:time", constraints: {"time" => /\d:\d:\d/})]
  def route_constraints(time : String) : String
    time
  end

  @[Athena::Routing::Post(path: "noParamsPostRequired")]
  def no_params_post_required(body : String) : String
    "foobar"
  end

  @[Athena::Routing::Post(path: "noParamsPostOptional")]
  def no_params_post_optional(body : String?) : String
    "foobar"
  end

  @[Athena::Routing::Post(path: "double/:val1")]
  def double_params_post(body : Int32, val1 : Int32) : Int32
    val1.should be_a Int32
    body.should be_a Int32
    val1.should eq 750
    body.should eq 250
    val1 + body
  end

  @[Athena::Routing::Get(path: "ecr_html")]
  @[Athena::Routing::View(renderer: Athena::Routing::Renderers::ECRRenderer)]
  def ecr_html : String
    # ameba:disable Lint/UselessAssign
    name = "John"
    ECR.render "spec/routing/greeting.ecr"
  end

  @[Athena::Routing::Get(path: "get/query_param_constraint_required", query: {"time" => /\d:\d:\d/})]
  def query_param_constraint_required(time : String) : String
    time
  end

  @[Athena::Routing::Get(path: "get/query_param_required", query: {"time" => nil})]
  def query_param_required(time : String) : String
    time
  end

  @[Athena::Routing::Get(path: "get/query_params_constraint_optional", query: {"time" => /\d:\d:\d/})]
  def query_param_optional_constraint(time : String?) : String?
    time
  end

  @[Athena::Routing::Get(path: "get/query_params_constraint_optional_default", query: {"time" => /\d:\d:\d/})]
  def query_param_optional_constraint_default(time : String? = "foo") : String?
    time
  end

  @[Athena::Routing::Get(path: "get/query_params_optional", query: {"time" => nil})]
  def query_param_optional(time : String?) : String?
    time
  end

  @[Athena::Routing::Get(path: "get/query_params_optional_default", query: {"page" => nil})]
  def query_param_optional_default(page : Int32? = 999) : Int32?
    page
  end

  @[Athena::Routing::Get(path: "get/custom_error")]
  def custom_error : Nil
    raise Athena::Routing::Exceptions::ImATeapotException.new "teapot"
  end

  @[Athena::Routing::Get(path: "get/response")]
  def response : Nil
    @request_stack.response.headers.add "Foo", "Bar"
  end

  @[Athena::Routing::Get(path: "get/request")]
  def request : String
    @request_stack.request.path
  end

  @[Athena::Routing::Get(path: "negative/:val")]
  def do_work(val : Int32) : Int32
    val.should be_a Int32
    val.should eq 123
    -val
  end

  @[Athena::Routing::Post(path: "negative")]
  def do_work_post(body : Int32) : Int32
    body.should be_a Int32
    body.should eq 123
    -body
  end

  @[Athena::Routing::Get(path: "get/nil_return")]
  def nil_return : Nil
    123
  end

  @[Athena::Routing::Get(path: "get/nil_return/updated_status")]
  def nil_return_updated_satus : Nil
    @request_stack.response.status = HTTP::Status::IM_A_TEAPOT
    123
  end
end
