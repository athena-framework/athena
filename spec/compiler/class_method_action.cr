require "../spec_helper"

class CompileController < Athena::Routing::Controller
  @[ART::Get(path: "/")]
  def self.class_method : Int32
    123
  end
end

ART.run
