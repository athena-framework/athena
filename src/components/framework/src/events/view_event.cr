require "./request_aware"
require "./settable_response"

# Emitted after the route's action has been executed, but only if it does _NOT_ return an `ATH::Response`.
#
# This event can be listened on to handle converting a non `ATH::Response` into an `ATH::Response`.
#
# See `ATH::Listeners::View` and the [external documentation](/architecture/#4-view-event) for more information.
class Athena::Framework::Events::View < AED::Event
  include Athena::Framework::Events::SettableResponse
  include Athena::Framework::Events::RequestAware

  private module ContainerBase; end

  private record ResultContainer(T), data : T do
    include ContainerBase
  end

  @result : ContainerBase

  def initialize(request : ATH::Request, action_result : _)
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
