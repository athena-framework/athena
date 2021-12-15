@[ASRA::Discriminator(key: "type", map: {"point" => Point, "circle" => Circle})]
abstract class Shape
  include ASR::Serializable

  property type : String
end

class Point < Shape
  property x : Int32
  property y : Int32
end

class Circle < Shape
  property x : Int32
  property y : Int32
  property radius : Int32
end
