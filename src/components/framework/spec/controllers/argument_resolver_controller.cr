@[ADI::Register(tags: [{name: ATHR::Interface::TAG, priority: 101}])]
class GenericAnnotationEnabledCustomResolver
  include ATHR::Interface

  configuration ::MyResolverAnnotation

  def initialize(
    @annotation_resolver : ATH::AnnotationResolver,
  ); end

  def resolve(request : AHTTP::Request, parameter : AHK::Controller::ParameterMetadata(Float64)) : Float64?
    return unless @annotation_resolver.action_parameter_annotations(request, parameter.name).has? MyResolverAnnotation

    3.14
  end

  def resolve(request : AHTTP::Request, parameter : AHK::Controller::ParameterMetadata(String)) : String?
    return unless @annotation_resolver.action_parameter_annotations(request, parameter.name).has? MyResolverAnnotation

    "fooo"
  end

  def resolve(request : AHTTP::Request, parameter : AHK::Controller::ParameterMetadata) : Nil
  end
end

@[ARTA::Route(path: "/argument-resolvers")]
class ArgumentResolverController < ATH::Controller
  @[ARTA::Post("/float")]
  def happy_path1(
    @[MyResolverAnnotation]
    value : Float64,
  ) : Float64
    value
  end

  @[ARTA::Post("/string")]
  def happy_path2(
    @[MyResolverAnnotation]
    value : String,
  ) : String
    value
  end
end
