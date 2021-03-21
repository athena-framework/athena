require "../spec_helper"

private record JSONSerializableModel, id : Int32, name : String do
  include JSON::Serializable
end

private record BothSerializableModel, id : Int32, name : String do
  include JSON::Serializable
  include ASR::Serializable

  @[ASRA::Groups("foo")]
  @name : String
end

@[ARTA::Prefix("view")]
class ViewController < ART::Controller
  @[ARTA::Get("/json")]
  def json_serializable : JSONSerializableModel
    JSONSerializableModel.new 10, "Bob"
  end

  @[ARTA::Get("/asr")]
  @[ARTA::View(serialization_groups: ["default"])]
  def both_serializable : BothSerializableModel
    BothSerializableModel.new 20, "Jim"
  end

  @[ARTA::Post("/status")]
  @[ARTA::View(status: :accepted)]
  def custom_status_code : String
    "foo"
  end
end
