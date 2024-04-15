@[ADI::Register(tags: [{name: ATHR::Interface::TAG, priority: 101}])]
class GenericAnnotationEnabledCustomResolver
  include ATHR::Interface

  configuration Enable

  def resolve(request : ATH::Request, parameter : ATH::Controller::ParameterMetadata(Float64, _, _, _)) : Float64?
    return unless parameter.annotation Enable

    3.14
  end

  def resolve(request : ATH::Request, parameter : ATH::Controller::ParameterMetadata(String, _, _, _)) : String?
    return unless parameter.annotation Enable

    "fooo"
  end

  def resolve(request : ATH::Request, parameter : ATH::Controller::ParameterMetadata) : Nil
  end
end

@[ARTA::Route(path: "/argument-resolvers")]
class ArgumentResolverController < ATH::Controller
  @[ARTA::Post("/float")]
  def happy_path1(
    @[GenericAnnotationEnabledCustomResolver::Enable]
    value : Float64
  ) : Float64
    value
  end

  @[ARTA::Post("/string")]
  def happy_path2(
    @[GenericAnnotationEnabledCustomResolver::Enable]
    value : String
  ) : String
    value
  end
end
