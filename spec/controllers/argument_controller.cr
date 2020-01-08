require "../spec_helper"

class ArgumentController < ART::Controller
  @[ART::Get(path: "/request")]
  def get_request(request : HTTP::Request) : String
    request.path
  end

  @[ART::Get(path: "/response")]
  def get_response(response : HTTP::Server::Response) : String
    response.status_code = 418
    response.version
  end

  @[ART::Get(path: "/not-nil/:id")]
  def argument_not_nil(id : Int32) : Int32
    id
  end

  @[ART::QueryParam("id")]
  @[ART::Get(path: "/not-nil-missing")]
  def argument_not_nil_missing(id : Int32) : Int32
    id
  end

  @[ART::QueryParam(name: "id")]
  @[ART::Get(path: "/not-nil-default")]
  def argument_not_nil_default(id : Int32 = 24) : Int32
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
end
