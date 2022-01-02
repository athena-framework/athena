# :nodoc:
@[ADI::Register(name: "router", public: true, alias: ART::Generator::Interface)]
class Athena::Framework::Routing::Router < Athena::Routing::Router
  def initialize(
    default_locale : String? = nil,
    strict_requirements : Bool = true,
    context : ART::RequestContext? = nil
  )
    super ATH::Routing::AnnotationRouteLoader.route_collection, default_locale, strict_requirements, context
  end
end
