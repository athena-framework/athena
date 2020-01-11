require "../spec_helper"

struct DoubleConverter(T)
  include ART::ParamConverterInterface(T)

  def convert(value : String) : T
    value.to_i * 2
  end
end

class ParamConverterController < ART::Controller
  @[ART::ParamConverter("num", converter: DoubleConverter(Int32))]
  @[ART::Get(path: "/double/:num")]
  def double(num : Int32) : Int32
    num
  end

  @[ART::QueryParam(name: "num", converter: DoubleConverter(Int32))]
  @[ART::Get(path: "/double-query")]
  def double_query(num : Int32) : Int32
    num
  end
end
