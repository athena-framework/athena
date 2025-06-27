require "../spec_helper"

enum EnumRequirementEnum
  A
  B
  C
end

@[Flags]
enum EnumRequirementEnumFlags
  A
  B
  C
end

struct EnumRequirementTest < ASPEC::TestCase
  def test_to_s_no_members : Nil
    ART::Requirement::Enum(EnumRequirementEnum).new.to_s.should eq "a|b|c"
    ART::Requirement::Enum(EnumRequirementEnumFlags).new.to_s.should eq "a|b|c"
  end

  def test_to_s_with_members : Nil
    ART::Requirement::Enum(EnumRequirementEnum).new(:a, :c).to_s.should eq "a|c"
    ART::Requirement::Enum(EnumRequirementEnumFlags).new(:b, :c).to_s.should eq "b|c"
  end

  @[Tags("compiled")]
  def test_constructor_non_enum_type : Nil
    self.assert_compile_time_error "'Int32' is not an Enum type.", <<-CR
      require "../spec_helper"
      ART::Requirement::Enum(Int32).new
    CR
  end
end
