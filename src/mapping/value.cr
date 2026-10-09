module Athena::ORM::Mapping
  # :nodoc:
  #
  # A field value that is neither a driver scalar nor an ORM reference, such as a value object produced by a custom `Types::Type`.
  # Being an abstract class, it takes a single slot in `ValueAny` however many concrete types get boxed, so the union every consumer of a `Value` handles stays the same size.
  abstract class Opaque
    # Converts the boxed value to its database representation through *type*, or returns it unchanged without one.
    abstract def to_db(type : Types::Type?, platform : Platforms::Platform)

    abstract def ==(other : Opaque) : Bool
  end

  # :nodoc:
  #
  # Boxes a value of the single concrete type *T*.
  # Only `Mapping.box` creates these, which guarantees *T* is never a union, so per-field code can unbox by the field's own type.
  class OpaqueValue(T) < Opaque
    getter value : T

    def initialize(@value : T); end

    def to_db(type : Types::Type?, platform : Platforms::Platform)
      type ? type.to_db(@value, platform) : @value
    end

    def ==(other : Opaque) : Bool
      other.is_a?(OpaqueValue(T)) && other.value == @value
    end

    def hash(hasher)
      @value.hash hasher
    end

    def to_s(io : IO) : Nil
      @value.to_s io
    end

    def inspect(io : IO) : Nil
      @value.inspect io
    end
  end

  # Declares the boxes for the built-in types' values that aren't driver scalars before main typing.
  # A box type first created during main typing makes the compiler re-type every call already typed through `Opaque+`, including those in each entity's mapping code.
  @@int16_box : OpaqueValue(Int16)? = nil
  @@uuid_box : OpaqueValue(UUID)? = nil

  macro finished
    {% if @top_level.has_constant?("BigDecimal") %}
      @@big_decimal_box : OpaqueValue(BigDecimal)? = nil
    {% end %}
  end

  # :nodoc:
  #
  # Everything the ORM stores in a `Mapping::Value`: driver scalars, ORM references (entities, including proxies, and collections), and boxed values of any other type.
  # Every member is a fixed-size type or a class hierarchy, so the union doesn't grow with the number of entities or collection types.
  alias ValueAny = ::DB::Any | Athena::ORM::Entity | Athena::ORM::BaseCollection | Opaque

  # :nodoc:
  #
  # Returns *value* as a `ValueAny`, boxing it in an `OpaqueValue` when it's neither a driver scalar nor an ORM reference.
  # Each member of a union is boxed as its own concrete type.
  def self.box(value : T) : ValueAny forall T
    {% begin %}
      {% for member in T.union_types %}
        {% if member <= Athena::ORM::Collection %}
          # Every `Collection` implementation is a `BaseCollection`; the explicit cast is needed because narrowing a value typed as the module with `is_a?(BaseCollection)` can be folded to false here.
          return value.as(Athena::ORM::BaseCollection) if value.is_a?({{member}})
        {% elsif member == Nil || member <= ::DB::Any || member <= Athena::ORM::Entity || member <= Athena::ORM::BaseCollection || member <= Opaque %}
          return value if value.is_a?({{member}})
        {% else %}
          return OpaqueValue({{member}}).new(value) if value.is_a?({{member}})
        {% end %}
      {% end %}
    {% end %}

    raise "BUG: unreachable for #{value.class} (static #{T})"
  end

  # :nodoc:
  abstract struct Value
    abstract def value : ValueAny
  end

  # :nodoc:
  record SingleValue < Value, value : ValueAny

  # :nodoc:
  record ColumnValue < Value, name : String, value : ValueAny do
    def to_s(io : IO) : Nil
      @value.to_s io
    end

    def inspect(io : IO) : Nil
      @value.inspect io
    end
  end
end
