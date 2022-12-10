# An extension of `AED::Event` that provides a generic event type that can be used in place of dedicated event types.
# Allows using various instantations of this one event type to handle multiple events.
#
# INFO: This type is provided for convience for use within simple use cases.
# Dedicated event types are still considered a best practice.
#
# ## Usage
#
# A generic event consists of a `#subject` of type `S`, which is some object/value representing an event that has occured.
# `#arguments` of type `V` may also be provided to augment the event with additional context, which is modeled as a `Hash(String, V)`.
#
# ```
# dispatcher.dispatch(
#   AED::GenericEvent(MyClass, Int32 | String).new(
#     my_class_instance,
#     {"counter" => 0, "data" => "bar"}
#   )
# )
# ```
#
# Refer to [AED::Event][Athena::EventDispatcher::Event--generics] for examples of how listeners on events with generics behave.
#
# TODO: Make this include `Mappable` when/if https://github.com/crystal-lang/crystal/issues/10886 is implemented.
class Athena::EventDispatcher::GenericEvent(S, V) < Athena::EventDispatcher::Event
  getter subject : S

  property arguments : Hash(String, V)

  def self.new(subject : S)
    AED::GenericEvent(S, NoReturn).new subject, Hash(String, NoReturn).new
  end

  def initialize(
    @subject : S,
    @arguments : Hash(String, V)
  ); end

  def [](key : String) : V
    @arguments[key]
  end

  def []?(key : String) : V?
    @arguments[key]?
  end

  def []=(key : String, value : V) : Nil
    @arguments[key] = value
  end

  def has_key?(key : String) : Bool
    @arguments.has_key? key
  end
end
