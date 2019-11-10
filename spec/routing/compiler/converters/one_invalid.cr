require "../../routing_spec_helper"

struct NoPk
  def self.find(id); end
end

struct Model
  def self.find(id); end
end

struct CompileController < Athena::Routing::Controller
  @[Athena::Routing::Post(path: "/:pk_id")]
  @[Athena::Routing::ParamConverter(param: "body", type: Model, converter: RequestBody)]
  @[Athena::Routing::ParamConverter(param: "body", type: NoPk, converter: Exists)]
  def one_invalid_converter(body : Model, pk : NoPk) : Int32
    123
  end
end

Athena::Routing.run
