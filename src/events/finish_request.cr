# Emitted after the route's action has been executed and response has been written but before the response has been returned.
#
# This event can be listened on to modify the response object's body IO; such as for compression,
# or to handle any cleanup that needs to happen before the response is returned.
class Athena::Routing::Events::FinishRequest < AED::Event
  include Athena::Routing::Events::Context
end
