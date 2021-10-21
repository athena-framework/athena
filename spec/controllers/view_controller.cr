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

@[ATHA::Prefix("view")]
class ViewController < ATH::Controller
  @[ATHA::Get("/json")]
  def json_serializable : JSONSerializableModel
    JSONSerializableModel.new 10, "Bob"
  end

  @[ATHA::Get("/json-array")]
  def json_array_serializable : Array(JSONSerializableModel)
    [
      JSONSerializableModel.new(10, "Bob"),
      JSONSerializableModel.new(20, "Sally"),
    ] of JSONSerializableModel
  end

  @[ATHA::Get("/json-array-nested")]
  def json_nested_array_serializable : Array(Array(JSONSerializableModel))
    [[
      JSONSerializableModel.new(10, "Bob"),
    ]]
  end

  @[ATHA::Get("/json-array-empty")]
  def json_empty_array_serializable : Array(JSONSerializableModel)
    [] of JSONSerializableModel
  end

  @[ATHA::Get("/asr")]
  @[ATHA::View(serialization_groups: ["default"])]
  def both_serializable : BothSerializableModel
    BothSerializableModel.new 20, "Jim"
  end

  @[ATHA::Get("/asr-array")]
  @[ATHA::View(serialization_groups: ["default"])]
  def both_serializable_array : Array(BothSerializableModel)
    [
      BothSerializableModel.new(10, "Bob"),
      BothSerializableModel.new(20, "Sally"),
    ]
  end

  @[ATHA::Post("/status")]
  @[ATHA::View(status: :accepted)]
  def custom_status_code : String
    "foo"
  end

  @[ATHA::Get("")]
  def view : ATH::View(String)
    self.view "DATA", :im_a_teapot
  end

  @[ATHA::Get("/array")]
  def view_array : ATH::View(Array(JSONSerializableModel))
    self.view(
      [
        JSONSerializableModel.new(10, "Bob"),
        JSONSerializableModel.new(20, "Sally"),
      ],
      :im_a_teapot
    )
  end
end
