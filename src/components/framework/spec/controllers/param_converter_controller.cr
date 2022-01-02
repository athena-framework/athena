@[ADI::Register]
class GenericConverter < ATH::ParamConverter
  def apply(request : ATH::Request, configuration : Configuration(T)) : Nil forall T
    value = case T
            in Int32.class  then 1
            in String.class then 2
            end

    request.attributes.set "value", value, Int32
  end
end

@[ADI::Register]
class SingleAdditionalGenericConverter < ATH::ParamConverter
  configuration type_vars: B

  def apply(request : ATH::Request, configuration : Configuration(A, B)) : Nil forall A, B
    value = 0

    value += case A
             in Int32.class  then 1
             in String.class then 2
             end

    value += case B
             in Int32.class  then 1
             in String.class then 2
             end

    request.attributes.set "value", value, Int32
  end
end

@[ADI::Register]
class MultipleAdditionalGenericConverter < ATH::ParamConverter
  configuration type_vars: {B, C}

  def apply(request : ATH::Request, configuration : Configuration(A, B, C)) : Nil forall A, B, C
    value = 0

    value += case A
             in Int32.class  then 1
             in String.class then 2
             end

    value += case B
             in Int32.class  then 1
             in String.class then 2
             end

    value += case C
             in Int32.class  then 1
             in String.class then 2
             end

    request.attributes.set "value", value, Int32
  end
end

@[ARTA::Route(path: "/param-converter")]
class ParamConverterController < ATH::Controller
  # Param converter type - single generic - arg type
  @[ARTA::Post("")]
  @[ATHA::ParamConverter("value", converter: GenericConverter)]
  def happy_path(value : Int32 = 0) : Int32
    value
  end

  # Param converter type - single additional generic
  @[ARTA::Post("/single-additional")]
  @[ATHA::ParamConverter("value", converter: SingleAdditionalGenericConverter, type_vars: Int32)]
  def single_additional_generic_arg(value : Int32 = 0) : Int32
    value
  end

  # Param converter type - multiple additional generic
  @[ARTA::Post("/multiple-additional")]
  @[ATHA::ParamConverter("value", converter: MultipleAdditionalGenericConverter, type_vars: {Int32, String})]
  def multiple_additional_generic_args(value : Int32 = 0) : Int32
    value
  end
end
