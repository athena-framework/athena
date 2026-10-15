require "./spec_helper"

struct VersionTest < ASPEC::TestCase
  def test_equality_is_by_value : Nil
    AORM::Migrations::Version::Version.new("A::Version1").should eq AORM::Migrations::Version::Version.new("A::Version1")
    AORM::Migrations::Version::Version.new("A::Version1").should_not eq AORM::Migrations::Version::Version.new("A::Version2")
  end

  def test_equal_versions_are_the_same_hash_key : Nil
    versions = {AORM::Migrations::Version::Version.new("A::Version1") => 1}

    versions[AORM::Migrations::Version::Version.new("A::Version1")]?.should eq 1
    versions[AORM::Migrations::Version::Version.new("A::Version2")]?.should be_nil
  end

  def test_to_s : Nil
    AORM::Migrations::Version::Version.new("A::Version1").to_s.should eq "A::Version1"
  end

  def test_direction_to_s : Nil
    AORM::Migrations::Version::Direction::UP.to_s.should eq "up"
    AORM::Migrations::Version::Direction::DOWN.to_s.should eq "down"
    "Direction: #{AORM::Migrations::Version::Direction::UP}".should eq "Direction: up"
  end
end
