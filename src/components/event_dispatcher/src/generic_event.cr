# An extension of `AED::Event` that provides a generic event type that can be used in place of dedicated event types.
# Allows using various instantiations of this one event type to handle multiple events.
#
# INFO: This type is provided for convenience for use within simple use cases.
# Dedicated event types are still considered a best practice.
#
# ## Usage
#
# A generic event consists of a `#subject` of type `S`, which is some object/value representing an event that has occurred.
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
  # Returns the subject of this event.
  getter subject : S

  # Returns the extra information stored with this event.
  getter arguments : Hash(String, V)

  # Sets the extra information that should be stored with this event.
  setter arguments : Hash(String, V)

  def self.new(subject : S)
    AED::GenericEvent(S, NoReturn).new subject, Hash(String, NoReturn).new
  end

  def initialize(
    @subject : S,
    @arguments : Hash(String, V),
  ); end

  # Returns the argument with the provided *key*, raising if it does not exist.
  def [](key : String) : V
    @arguments[key]
  end

  # Returns the argument with the provided *key*, or `nil` if it does not exist.
  def []?(key : String) : V?
    @arguments[key]?
  end

  # Sets the argument with the provided *key* to the provided *value*.
  def []=(key : String, value : V) : Nil
    @arguments[key] = value
  end

  # Returns `true` if there is an argument with the provided *key*, otherwise `false`.
  def has_key?(key : String) : Bool
    @arguments.has_key? key
  end
end
