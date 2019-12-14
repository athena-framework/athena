require "../routing_spec_helper"

struct DoubleConverter(T) < ART::Converters::Converter(T)
  def convert(value : String)
    value.to_i * 2
  end
end

struct ArgumentController < ART::Controller
  @[ART::Get(path: "/request")]
  def get_request(request : HTTP::Request) : String
    request.path
  end

  @[ART::Get(path: "/not-nil/:id")]
  def argument_not_nil(id : Int32) : Int32
    id
  end

  @[ART::QueryParam(name: "id")]
  @[ART::Get(path: "/not-nil-missing")]
  def argument_not_nil_missing(id : Int32) : Int32
    id
  end

  @[ART::QueryParam(name: "id")]
  @[ART::Get(path: "/not-nil-default")]
  def argument_not_nil_default(id : Int32 = 19) : Int32
    id
  end

  @[ART::QueryParam(name: "id")]
  @[ART::Get(path: "/nil")]
  def argument_nil(id : Int32?) : Int32?
    id
  end

  @[ART::QueryParam(name: "id")]
  @[ART::Get(path: "/nil-default")]
  def argument_nil_default(id : Int32? = 19) : Int32?
    id
  end

  @[ART::ParamConverter("num", converter: DoubleConverter(Int32))]
  @[ART::Get(path: "/double/:num")]
  def double(num : Int32) : Int32
    num
  end
end
