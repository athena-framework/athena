# Emitted after the route's action has been executed and response has been written.
#
# This event can be listened on to modify the response object further before it is returned; such as adding headers/cookies etc.
class Athena::Routing::Events::Response < AED::Event
  include Athena::Routing::Events::Context
end
