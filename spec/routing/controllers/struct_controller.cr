struct SController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "struct/:val")]
  def self.do_work(val : Int32) : Int32
    val.should be_a Int32
    val.should eq 123
    -val
  end

  @[Athena::Routing::Post(path: "struct")]
  def self.do_work_post(body : Int32) : Int32
    body.should be_a Int32
    body.should eq 123
    -body
  end

  @[Athena::Routing::Get(path: "get/struct/response")]
  def self.response : Nil
    get_response.headers.add "Foo", "Bar"
  end

  @[Athena::Routing::Get(path: "get/struct/request")]
  def self.request : String
    get_request.path
  end
end
