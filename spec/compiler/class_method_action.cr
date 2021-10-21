require "../spec_helper"

class CompileController < Athena::Framework::Controller
  @[ARTA::Get(path: "/")]
  def self.class_method : Int32
    123
  end
end

ATH.run
