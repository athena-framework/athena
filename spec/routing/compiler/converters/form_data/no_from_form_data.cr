require "../../../routing_spec_helper"

struct NoFormData
end

struct CompileController < Athena::Routing::Controller
  @[Athena::Routing::Post(path: "/")]
  @[Athena::Routing::ParamConverter(param: "body", type: NoFormData, converter: FormData)]
  def no_from_data(body : NoFormData) : Int32
    123
  end
end

Athena::Routing.run
