require "../spec_helper"

struct MappingValueTest < ASPEC::TestCase
  def test_box_passes_driver_scalars_through : Nil
    AORM::Mapping.box("abc").should eq "abc"
    AORM::Mapping.box(1).should eq 1
    AORM::Mapping.box(nil).should be_nil
  end

  def test_box_passes_orm_references_through : Nil
    avatar = ForumAvatar.new

    AORM::Mapping.box(avatar).should be avatar
  end

  # Collection fields are typed as the `Collection(T)` module; they must still be stored as references rather than boxed.
  def test_box_passes_collections_typed_as_the_collection_module_through : Nil
    collection = AORM::ArrayCollection(CmsGroup).new

    AORM::Mapping.box(collection.as(AORM::Collection(CmsGroup))).should be collection
  end

  def test_box_wraps_other_types_in_an_opaque_value : Nil
    boxed = AORM::Mapping.box CustomIdObject.new("abc")

    boxed.should be_a AORM::Mapping::OpaqueValue(CustomIdObject)
    boxed.as(AORM::Mapping::OpaqueValue(CustomIdObject)).value.should eq CustomIdObject.new("abc")
  end

  # Each box holds exactly one concrete type, so the field macros can unbox it by that type.
  def test_box_wraps_each_union_member_as_its_own_type : Nil
    values = [CustomIdObject.new("abc"), 1.second] of CustomIdObject | Time::Span

    AORM::Mapping.box(values[0]).should be_a AORM::Mapping::OpaqueValue(CustomIdObject)
    AORM::Mapping.box(values[1]).should be_a AORM::Mapping::OpaqueValue(Time::Span)
  end

  def test_box_does_not_rewrap_an_opaque_value : Nil
    boxed = AORM::Mapping.box CustomIdObject.new("abc")

    AORM::Mapping.box(boxed).should be boxed
  end

  # Change detection compares stored values, so equal value objects must not look like a change.
  def test_opaque_values_compare_by_their_wrapped_value : Nil
    boxed = AORM::Mapping.box CustomIdObject.new("abc")

    (boxed == AORM::Mapping.box(CustomIdObject.new("abc"))).should be_true
    (boxed == AORM::Mapping.box(CustomIdObject.new("xyz"))).should be_false
    (boxed == AORM::Mapping.box(1.second)).should be_false
  end

  # Identity-map keys are built from the string form of identifier values.
  def test_opaque_value_renders_as_its_wrapped_value : Nil
    AORM::Mapping.box(CustomIdObject.new("abc")).to_s.should eq "abc"
  end

  def test_opaque_value_converts_through_the_given_type : Nil
    boxed = AORM::Mapping::OpaqueValue.new CustomIdObject.new("abc")

    boxed.to_db(CustomIdObjectType.new, MockPlatform.new).should eq "abc"
    boxed.to_db(nil, MockPlatform.new).should eq CustomIdObject.new("abc")
  end
end
