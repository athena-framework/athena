# :nodoc:
@[ADI::Register(_default_uri: "%routing.base_uri%", name: "router", public: true, alias: [ART::Generator::Interface, ART::Matcher::URLMatcherInterface, ART::RouterInterface])]
class Athena::Framework::Routing::Router < Athena::Routing::Router
  getter matcher : ART::Matcher::URLMatcherInterface do
    ATH::Routing::RedirectableURLMatcher.new(@context)
  end

  def initialize(
    default_locale : String? = nil,
    strict_requirements : Bool = true,
    base_uri : String? = nil
  )
    super(ATH::Routing::AnnotationRouteLoader.route_collection,
      default_locale,
      strict_requirements,
      base_uri.try { |uri| ART::RequestContext.from_uri uri }
    )
  end
end
