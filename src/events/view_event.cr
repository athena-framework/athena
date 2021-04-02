require "./request_aware"
require "./settable_response"

# Emitted after the route's action has been executed, but only if it does _NOT_ return an `ART::Response`.
#
# This event can be listened on to handle converting a non `ART::Response` into an `ART::Response`.
#
# See `ART::Listeners::View` and the [external documentation](/components/#4-view-event) for more information.
class Athena::Routing::Events::View < AED::Event
  include Athena::Routing::Events::SettableResponse
  include Athena::Routing::Events::RequestAware

  private module ContainerBase; end

  private record ResultContainer(T), data : T do
    include ContainerBase
  end

  @result : ContainerBase

  def initialize(request : ART::Request, action_result : _)
    super request

    @result = ResultContainer.new action_result
  end

  # Returns the value returned from the related controller action.
  def action_result
    @result.data
  end

  # Overrides the return value of the related controller action.
  #
  # Can be used to mutate the controller action's returned value within a listener context;
  # such as for pagination.
  def action_result=(value : _) : Nil
    @result = ResultContainer.new value
  end
end
