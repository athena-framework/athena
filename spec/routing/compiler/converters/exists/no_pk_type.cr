require "../../../routing_spec_helper"

class NoPk
  def self.find(id); end
end

class CompileController < Athena::Routing::Controller
  @[Athena::Routing::Post(path: "/")]
  @[Athena::Routing::ParamConverter(param: "body", type: NoPk, converter: Exists)]
  def no_pk_type(body : NoPk) : Int32
    123
  end
end

Athena::Routing.run
