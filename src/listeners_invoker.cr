# :nodoc:
#
# Invokes the lifecycle callbacks an entity registered for an event.
class Athena::ORM::ListenersInvoker
  def initialize(@em : AORM::EntityManagerInterface); end

  def invoke(class_metadata : Mapping::ClassInterface, entity : AORM::Entity, event : T) : Nil forall T
    # TODO: Maybe should optimize this a bit more?
    class_metadata.lifecycle_callbacks[event.class]?.try &.each do |callback|
      callback.call entity, event
    end
  end
end
