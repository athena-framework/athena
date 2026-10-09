# Holds an instance of every known `AORM::Types::Type`, keyed by name.
#
# The registry used by the ORM is available as `AORM::Types::Type.type_registry`, though types are usually registered through `AORM::Types::Type.add_type`.
struct Athena::ORM::Types::TypeRegistry
  # Returns the registered types, keyed by name.
  getter instances = Hash(::String, AORM::Types::Type).new

  # Creates a registry holding *instances*, keyed by name.
  def initialize(instances : Hash(::String, AORM::Types::Type) = {} of ::String => AORM::Types::Type)
    instances.each do |name, type|
      register(name, type)
    end
  end

  # Returns the type registered as *name*.
  #
  # Raises if no type is registered with that name.
  def get(name : ::String) : AORM::Types::Type
    @instances[name]? || raise "Unknown type: #{name}"
  end

  # Returns `true` if a type is registered as *name*.
  def has?(name : ::String) : Bool
    @instances.has_key?(name)
  end

  # Registers *type* as *name*.
  #
  # Raises if a type is already registered with that name.
  def register(name : ::String, type : AORM::Types::Type) : Nil
    raise "Type '#{name}' already exists" if @instances.has_key?(name)
    @instances[name] = type
  end

  # Replaces the type registered as *name* with *type*.
  #
  # Raises if no type is registered with that name.
  def override(name : ::String, type : AORM::Types::Type) : Nil
    raise "Type '#{name}' not found" unless @instances.has_key?(name)
    @instances[name] = type
  end
end
