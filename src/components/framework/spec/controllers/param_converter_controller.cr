@[ADI::Register(tags: [{name: ATH::Arguments::Resolvers::TAG}])]
class GenericCustomResolver
  include Athena::Framework::Arguments::Resolvers::Interface

  def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata(T)) : Int32? forall T
    case T
    when Int32.class then 1
    end
  end
end

@[ADI::Register(tags: [{name: ATH::Arguments::Resolvers::TAG}])]
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
  @[ARTA::Post("")]
  def happy_path1(value : Int32 = 0) : Int32
    value
  end

  @[ARTA::Post("/float")]
  def happy_path2(
    @[GenericAnnotationEnabledCustomResolver::Enable]
    value : Float64
  ) : Float64
    value
  end

  @[ARTA::Post("/string")]
  def happy_path3(
    @[GenericAnnotationEnabledCustomResolver::Enable]
    value : String
  ) : String
    value
  end
end
