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
  @[ART::Get(path: "/double/:num")]
  @[ART::ParamConverter("doubled_num", converter: DoubleConverter(Int32))]
  def double(doubled_num : Int32) : Int32
    doubled_num
  end

  @[ART::Get(path: "/double-query")]
  @[ART::QueryParam("num", converter: DoubleConverter(Int32))]
  def double_query(num : Int32) : Int32
    num
  end

  @[ART::Post(path: "/user")]
  @[ART::ParamConverter("obj", converter: RequestBodyConverter(NamedTuple(name: String, id: Int32)))]
  def new_type(obj : NamedTuple(name: String, id: Int32)) : Int32
    obj["id"]
  end

  @[ART::Post("type")]
  @[ART::QueryParam("id")]
  @[ART::ParamConverter("obj", converter: RequestBodyConverter(NamedTuple(name: String, id: Int32)))]
  def new_type_post_qp(id : Int32, obj : NamedTuple(name: String, id: Int32)) : Int32
    obj["id"] + id
  end
end
