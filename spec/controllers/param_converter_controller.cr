require "../spec_helper"

struct DoubleConverter(T)
  include ART::ParamConverterInterface(T)

  def convert(request : HTTP::Request) : T
    (request.query_params["num"]? || request.path_params["num"]).to_i * 2
  end
end

class RequestBodyConverter(T)
  include ART::ParamConverterInterface(T)

  def convert(request : HTTP::Request) : T
    T.from_json request.body.not_nil!
  end
end

class ParamConverterController < ART::Controller
  @[ART::ParamConverter("doubled_num", converter: DoubleConverter(Int32))]
  @[ART::Get(path: "/double/:num")]
  def double(doubled_num : Int32) : Int32
    doubled_num
  end

  @[ART::QueryParam(name: "num", converter: DoubleConverter(Int32))]
  @[ART::Get(path: "/double-query")]
  def double_query(num : Int32) : Int32
    num
  end

  @[ART::QueryParam(name: "obj", converter: RequestBodyConverter(NamedTuple(name: String, id: Int32)))]
  @[ART::Post(path: "/user")]
  def new_type(obj : NamedTuple(name: String, id: Int32)) : Int32
    obj["id"]
  end
end
