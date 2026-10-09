require "../spec_helper"

# Minimal `Type` subclass with a marker field so spec assertions can tell two
# instances apart (Type subclasses are structs, so identity-via-`same?` doesn't
# apply — we compare by field value instead).
private struct MarkerType < AORM::Types::Type
  getter marker : Int32

  def initialize(@marker : Int32 = 0); end

  def sql_declaration(column : Sechema::Column, platform : AORM::Platforms::Platform) : String
    "MARKER#{@marker}"
  end

  def to_crystal_value(value : _, platform : AORM::Platforms::Platform)
    value
  end
end

struct TypeRegistryTest < ASPEC::TestCase
  def test_get_returns_the_registered_type : Nil
    registry = AORM::Types::TypeRegistry.new({"x" => MarkerType.new(7).as(AORM::Types::Type)})

    registry.get("x").as(MarkerType).marker.should eq 7
  end

  def test_get_returns_an_equivalent_value_on_repeated_lookups : Nil
    registry = AORM::Types::TypeRegistry.new({"x" => MarkerType.new(42).as(AORM::Types::Type)})

    # Structs are compared by value; two reads of the same registered slot
    # must yield the same marker.
    registry.get("x").should eq registry.get("x")
  end

  def test_get_raises_for_an_unknown_name : Nil
    registry = AORM::Types::TypeRegistry.new

    expect_raises(Exception, /Unknown type: nope/) do
      registry.get("nope")
    end
  end

  def test_has_distinguishes_registered_from_unregistered_names : Nil
    registry = AORM::Types::TypeRegistry.new({"x" => MarkerType.new(1).as(AORM::Types::Type)})

    registry.has?("x").should be_true
    registry.has?("nope").should be_false
  end

  def test_register_adds_a_new_type : Nil
    registry = AORM::Types::TypeRegistry.new

    registry.register("x", MarkerType.new(9))

    registry.get("x").as(MarkerType).marker.should eq 9
  end

  def test_register_raises_when_the_name_already_exists : Nil
    registry = AORM::Types::TypeRegistry.new({"x" => MarkerType.new(1).as(AORM::Types::Type)})

    expect_raises(Exception, /'x' already exists/) do
      registry.register("x", MarkerType.new(2))
    end
  end

  def test_override_replaces_an_existing_type : Nil
    registry = AORM::Types::TypeRegistry.new({"x" => MarkerType.new(1).as(AORM::Types::Type)})

    registry.override("x", MarkerType.new(99))

    registry.get("x").as(MarkerType).marker.should eq 99
  end

  def test_override_raises_for_an_unknown_name : Nil
    registry = AORM::Types::TypeRegistry.new

    expect_raises(Exception, /'nope' not found/) do
      registry.override("nope", MarkerType.new(1))
    end
  end

  def test_constructor_seeds_the_registry_with_initial_instances : Nil
    registry = AORM::Types::TypeRegistry.new({
      "a" => MarkerType.new(10).as(AORM::Types::Type),
      "b" => MarkerType.new(20).as(AORM::Types::Type),
    })

    registry.get("a").as(MarkerType).marker.should eq 10
    registry.get("b").as(MarkerType).marker.should eq 20
  end
end
