# Emitted very late in the request's life-cycle, after the response has been sent.
#
# This event can be listened on to perform tasks that are not required to finish before the response is sent.
class Athena::Routing::Events::Terminate < AED::Event
  include Athena::Routing::Events::Context
end
