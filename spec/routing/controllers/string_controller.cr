struct StringController < Athena::Routing::StructController
  @[Athena::Routing::Get(path: "string/:val")]
  def self.string(val : String) : String
    val.should be_a String
    val.should eq "sdfsd"
    val
  end

  @[Athena::Routing::Post(path: "string")]
  def self.string_post(body : String) : String
    body.should be_a String
    body.should eq "sdfsd"
    body
  end
end
