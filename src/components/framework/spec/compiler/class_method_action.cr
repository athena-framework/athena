require "../spec_helper"

class CompileController < Athena::Framework::Controller
  @[ATHA::Get(path: "/")]
  def self.class_method : Int32
    123
  end
end

ATH.run
