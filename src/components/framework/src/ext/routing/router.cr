# :nodoc:
@[ADI::AsAlias(ART::Generator::Interface)]
@[ADI::AsAlias(ART::Matcher::URLMatcherInterface)]
@[ADI::AsAlias(ART::RouterInterface)]
@[ADI::AsAlias(ART::RequestContextAwareInterface)]
@[ADI::AsAlias("router", public: true)]
class Athena::Framework::Routing::Router < Athena::Routing::Router
  getter matcher : ART::Matcher::URLMatcherInterface do
    ATH::Routing::RedirectableURLMatcher.new(@context)
  end

  def initialize(
    default_locale : String? = nil,
    strict_requirements : Bool? = true,
    request_context : ART::RequestContext? = nil,
  )
    super(
      ATH::Routing::AnnotationRouteLoader.route_collection,
      default_locale,
      strict_requirements,
      request_context,
    )
  end
end
