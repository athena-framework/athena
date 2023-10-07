require "./request_aware"

# Emitted after `ATH::Events::Request` and the related `ATH::Action` has been resolved, but before it has been executed.
#
# See the [external documentation](../../../architecture/README.md#2-action-event) for more information.
class Athena::Framework::Events::Action < AED::Event
  include Athena::Framework::Events::RequestAware

  # The related `ATH::Action` that will be used to handle the current request.
  getter action : ATH::ActionBase

  def initialize(request : ATH::Request, @action : ATH::ActionBase)
    super request
  end
end
