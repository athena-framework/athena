# Can be applied to method(s) within a type including `AED::EventListenerInterface` to denote that method is an event listener.
# The annotation expects to be assigned to an instance method with between 1 and 2 parameters with a return type of `Nil`.
# The first parameter should be the concrete `AED::Event` instance the method is listening on.
# The optional second parameter should be typed as an `AED::EventDispatcherInterface`.
#
# The annotation accepts an optional `priority` field, defaulting to `0`, denoting the [listener's priority][Athena::EventDispatcher::EventDispatcherInterface--listener-priority]
#
# ```
# class MyListener
#   include AED::EventListenerInterface
#
#   # Single parameter
#   @[AEDA::AsEventListener]
#   def single_param(event : MyEvent) : Nil
#   end
#
#   # Double parameter
#   @[AEDA::AsEventListener]
#   def double_param(event : MyEvent, dispatcher : AED::EventDispatcherInterface) : Nil
#   end
#
#   # With priority
#   @[AEDA::AsEventListener(priority: 10)]
#   def with_priority(event : MyEvent) : Nil
#   end
# end
# ```
annotation Athena::EventDispatcher::Annotations::AsEventListener; end
