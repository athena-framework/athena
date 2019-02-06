struct SController < Athena::Routing::StructController
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
end
