# A service with state, such as a cache of loaded objects, which should be reset before the service is used for another unit of work, such as another request.
#
# ```
# class RequestCounter
#   include ACTR::Service::Resettable
#
#   getter count : Int32 = 0
#
#   def increment : Nil
#     @count += 1
#   end
#
#   def reset : Nil
#     @count = 0
#   end
# end
# ```
#
# The [Athena Framework](/Framework/) gives each request its own service container, except for the requests made within a test, which share the test's container, see [ATH::Spec::ContainerTestCase](/Framework/Spec/ContainerTestCase/).
# It resets each of its `ACTR::Service::Resettable` services after each of those requests.
#
# TIP: Prefer stateless services where possible.
module Athena::Contracts::Service::Resettable
  # Puts `self` back into the state it had when it was first ready to use.
  abstract def reset : Nil
end
