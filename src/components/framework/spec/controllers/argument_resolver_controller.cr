@[ADI::Register(tags: [{name: ATH::Arguments::Resolvers::TAG, priority: 101}])]
class GenericAnnotationEnabledCustomResolver
  include Athena::Framework::Arguments::Resolvers::Interface

  configuration Enable

  def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata(Float64)) : Float64?
    return unless argument.annotation_configurations.has? Enable

    3.14
  end

  def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata(String)) : String?
    return unless argument.annotation_configurations.has? Enable

    "fooo"
  end

  def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata) : Nil
  end
end

@[ARTA::Route(path: "/param-converter")]
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
