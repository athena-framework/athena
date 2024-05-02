# :nodoc:
module Athena::Framework::ControllerResolverInterface
  abstract def resolve(request : ATH::Request) : ATH::ActionBase
end

@[ADI::Register]
@[ADI::AsAlias]
# :nodoc:
class Athena::Framework::ControllerResolver
  include Athena::Framework::ControllerResolverInterface

  def resolve(request : ATH::Request) : ATH::ActionBase
    ATH::Routing::AnnotationRouteLoader.actions[request.attributes.get "_controller"]
  end
end
