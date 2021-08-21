@[ADI::Register]
struct QPGenericConverter < Athena::Routing::ParamConverterInterface
  def apply(request : ART::Request, configuration : Configuration(T)) : Nil forall T
    value = case T
            in Int32.class  then 1
            in String.class then 2
            end

    request.attributes.set "value", value, Int32
  end
end

@[ADI::Register]
struct SingleAdditionalQPGenericConverter < Athena::Routing::ParamConverterInterface
  configuration type_vars: B

  def apply(request : ART::Request, configuration : Configuration(A, B)) : Nil forall A, B
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
struct MultipleAdditionalQPGenericConverter < Athena::Routing::ParamConverterInterface
  configuration type_vars: {B, C}

  def apply(request : ART::Request, configuration : Configuration(A, B, C)) : Nil forall A, B, C
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

# struct MultipleGenericConverter < Athena::Routing::ParamConverterInterface
#   configuration type_vars: {A, B}

#   def apply(request : ART::Request, configuration : Configuration) : Nil; end
# end

@[ARTA::Prefix("query")]
class QueryParamController < ART::Controller
  # Simple, just name/description
  @[ARTA::QueryParam("search", description: "Only return items that include this string.")]
  @[ARTA::Get("/")]
  def search(search : String) : String
    search
  end

  # Regex requirement
  @[ARTA::QueryParam("page", requirements: /\d+/)]
  @[ARTA::Get("/page")]
  def page(page : Int32 = 5) : Int32
    page
  end

  # Regex requirement, not strict, nilable
  @[ARTA::QueryParam("page", requirements: /\d+/, strict: false)]
  @[ARTA::Get("/page-nilable")]
  def page_nilable(page : Int32?) : Int32?
    page
  end

  # Regex requirement, strict, nilable
  @[ARTA::QueryParam("page", requirements: /1\d/)]
  @[ARTA::Get("/page-nilable-strict")]
  def page_nilable_strict(page : Int32?) : Int32?
    page
  end

  # Annotation requirement (not blank)
  @[ARTA::QueryParam("search", requirements: @[Assert::NotBlank])]
  @[ARTA::Get("/annotation")]
  def not_blank(search : String) : String
    search
  end

  # Array value, map: true
  @[ARTA::QueryParam("ids", map: true, requirements: [@[Assert::PositiveOrZero], @[Assert::Range(-1.0..10)]])]
  @[ARTA::Get("/ids")]
  def ids(ids : Array(Float64)) : Array(Float64)
    ids
  end

  # Incompatibilites
  @[ARTA::QueryParam("search", requirements: /\w+/)]
  @[ARTA::QueryParam("by_author", requirements: /\w+/, incompatibles: ["search"])]
  @[ARTA::Get("/searchv1")]
  def search_v1(search : String?, by_author : String?) : String?
    search || by_author
  end

  # Param converter type
  @[ARTA::QueryParam("time", converter: ART::TimeConverter)]
  @[ARTA::Get("/time")]
  def time(time : Time = Time.utc(2020, 10, 1)) : String
    "Today is: #{time}"
  end

  # Param converter type - single generic - arg type
  @[ARTA::QueryParam("value", converter: QPGenericConverter)]
  @[ARTA::Get("/generic/single")]
  def generic_arg_converter(value : Int32 = 0) : Int32
    value
  end

  # Param converter type - single additional generic
  @[ARTA::QueryParam("value", converter: {name: SingleAdditionalQPGenericConverter, type_vars: Int32})]
  @[ARTA::Get("/generic/single-additional")]
  def generic_arg_converter_single_additional(value : Int32 = 0) : Int32
    value
  end

  # Param converter type - multiple additional generic
  @[ARTA::QueryParam("value", converter: {name: MultipleAdditionalQPGenericConverter, type_vars: {Int32, String}})]
  @[ARTA::Get("/generic/multiple-additional")]
  def generic_arg_converter_multiple_additional(value : Int32 = 0) : Int32
    value
  end

  # Param converter named tuple
  @[ARTA::QueryParam("time", converter: {name: ART::TimeConverter, format: "%Y--%m//%d  %T"})]
  @[ARTA::Get("/nt_time")]
  def nt_time(time : Time) : String
    "Today is: #{time}"
  end

  # Request param
  @[ARTA::RequestParam("username")]
  @[ARTA::RequestParam("password")]
  @[ARTA::Post("/login")]
  def login(username : String, password : String) : String
    Base64.strict_encode "#{username}:#{password}"
  end
end
