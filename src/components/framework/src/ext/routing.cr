require "athena-routing"

require "./routing/*"

@[ADI::Register(alias: ART::Generator::Interface)]
class Athena::Framework::Routing::Router < Athena::Routing::Router
  def initialize(
    default_locale : String? = nil,
    strict_requirements : Bool = true,
    context : ART::RequestContext? = nil
  )
    super ART::RouteCollection.new, default_locale, strict_requirements, context
  end
end
