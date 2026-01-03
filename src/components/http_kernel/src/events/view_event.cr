# Emitted after the route's action has been executed, but only if it does _NOT_ return an [AHTTP::Response](/HTTP/Response).
#
# This event can be listened on to handle converting a non `AHTTP::Response` into an `AHTTP::Response`.
#
# See the [Getting Started](/getting_started/middleware#4-view-event) docs for more information.
class Athena::HTTPKernel::Events::View < ACTR::EventDispatcher::Event
  include Athena::HTTPKernel::Events::SettableResponse
  include Athena::HTTPKernel::Events::RequestAware

  private module ContainerBase; end

  private record ResultContainer(T), data : T do
    include ContainerBase

    # :inherit:
    def inspect(io : IO) : Nil
      io << "#<ViewResult(" << {{ T.stringify }} << ")>"
    end
  end

  @result : ContainerBase

  def initialize(request : AHTTP::Request, action_result : _)
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
