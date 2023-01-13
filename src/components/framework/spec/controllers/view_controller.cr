require "../spec_helper"

record JSONSerializableModel, id : Int32, name : String do
  include JSON::Serializable
end

private record BothSerializableModel, id : Int32, name : String do
  include JSON::Serializable
  include ASR::Serializable

  @[ASRA::Groups("foo")]
  @name : String
end

@[ARTA::Route(path: "view")]
class ViewController < ATH::Controller
  @[ARTA::Get("/json")]
  def json_serializable : JSONSerializableModel
    JSONSerializableModel.new 10, "Bob"
  end

  @[ARTA::Get("/json-array")]
  def json_array_serializable : Array(JSONSerializableModel)
    [
      JSONSerializableModel.new(10, "Bob"),
      JSONSerializableModel.new(20, "Sally"),
    ] of JSONSerializableModel
  end

  @[ARTA::Get("/json-array-nested")]
  def json_nested_array_serializable : Array(Array(JSONSerializableModel))
    [[
      JSONSerializableModel.new(10, "Bob"),
    ]]
  end

  @[ARTA::Get("/json-array-empty")]
  def json_empty_array_serializable : Array(JSONSerializableModel)
    [] of JSONSerializableModel
  end

  @[ARTA::Get("/asr")]
  @[ATHA::View(serialization_groups: ["default"])]
  def both_serializable : BothSerializableModel
    BothSerializableModel.new 20, "Jim"
  end

  @[ARTA::Get("/asr-array")]
  @[ATHA::View(serialization_groups: ["default"])]
  def both_serializable_array : Array(BothSerializableModel)
    [
      BothSerializableModel.new(10, "Bob"),
      BothSerializableModel.new(20, "Sally"),
    ]
  end

  @[ARTA::Get("/json-nested-hash-collection")]
  def nested_json_hash_collection : Hash(String, Int32 | JSONSerializableModel)
    {"foo" => 10, "obj" => JSONSerializableModel.new(10, "Bob")}
  end

  @[ARTA::Get("/json-nested-nt-collection")]
  def nested_json_nt_collection : {foo: Int32, obj: JSONSerializableModel}
    {foo: 10, obj: JSONSerializableModel.new(10, "Bob")}
  end

  @[ARTA::Get("/json-nested-hash-array-collection")]
  def nested_json_hash_array_collection : Hash(String, Int32 | Array(JSONSerializableModel))
    {"foo" => 10, "objs" => [JSONSerializableModel.new(10, "Bob")]}
  end

  @[ARTA::Get("/json-nested-nt-array-collection")]
  def nested_json_nt_array_collection : {foo: Int32, objs: Array(JSONSerializableModel)}
    {foo: 10, objs: [JSONSerializableModel.new(10, "Bob")]}
  end

  @[ARTA::Post("/status")]
  @[ATHA::View(status: :accepted)]
  def custom_status_code : String
    "foo"
  end

  @[ARTA::Get("")]
  def view : ATH::View(String)
    self.view "DATA", :im_a_teapot
  end

  @[ARTA::Get("/array")]
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
