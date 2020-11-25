@[ART::Prefix("query")]
class QueryParamController < ART::Controller
  # Simple, just name/description
  @[ART::QueryParam("search", description: "Only return items that include this string.")]
  @[ART::Get("/")]
  def search(search : String) : String
    search
  end

  # Regex requirement
  @[ART::QueryParam("page", requirements: /\d+/)]
  @[ART::Get("/page")]
  def page(page : Int32 = 5) : Int32
    page
  end

  # Regex requirement, not strict, nilable
  @[ART::QueryParam("page", requirements: /\d+/, strict: false)]
  @[ART::Get("/page-nilable")]
  def page_nilable(page : Int32?) : Int32?
    page
  end

  # Regex requirement, strict, nilable
  @[ART::QueryParam("page", requirements: /1\d/)]
  @[ART::Get("/page-nilable-strict")]
  def page_nilable_strict(page : Int32?) : Int32?
    page
  end

  # Annotation requirement (not blank)
  @[ART::QueryParam("search", requirements: @[Assert::NotBlank])]
  @[ART::Get("/annotation")]
  def not_blank(search : String) : String
    search
  end

  # Array value, map: true
  @[ART::QueryParam("ids", map: true, requirements: [@[Assert::PositiveOrZero], @[Assert::Range(-1.0..10)]])]
  @[ART::Get("/ids")]
  def ids(ids : Array(Float64)) : Array(Float64)
    ids
  end

  # Incompatibilites
  @[ART::QueryParam("search", requirements: /\w+/)]
  @[ART::QueryParam("by_author", requirements: /\w+/, incompatibles: ["search"])]
  @[ART::Get("/searchv1")]
  def search_v1(search : String?, by_author : String?) : String?
    search || by_author
  end

  # Param converter type
  @[ART::QueryParam("time", converter: ART::TimeConverter)]
  @[ART::Get("/time")]
  def time(time : Time = Time.utc(2020, 10, 1)) : String
    "Today is: #{time}"
  end

  # Param converter named tuple
  @[ART::QueryParam("time", converter: {name: ART::TimeConverter, format: "%Y--%m//%d  %T"})]
  @[ART::Get("/nt_time")]
  def nt_time(time : Time) : String
    "Today is: #{time}"
  end

  # Request param
  @[ART::RequestParam("username")]
  @[ART::RequestParam("password")]
  @[ART::Post("/login")]
  def login(username : String, password : String) : String
    Base64.strict_encode "#{username}:#{password}"
  end
end
