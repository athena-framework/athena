require "../../spec_helper"

struct AbstractTokenTest < ASPEC::TestCase
  def test_initialize : Nil
    TestToken.new(["ROLE_FOO"]).role_names.should eq ["ROLE_FOO"]
  end

  def test_user : Nil
    user = ASEC::User::InMemory.new "fabien", nil
    token = TestToken.new ["ROLE_FOO"]

    token.user.should be_nil
    token.user_identifier.should be_empty

    token.user = user

    token.user.should be user
    token.user_identifier.should eq "fabien"
  end

  def test_role_names_are_not_updated_with_the_user : Nil
    token = TestToken.new ["ROLE_FOO"]
    token.user = ASEC::User::InMemory.new "fabien", nil, ["ROLE_BAR"]

    token.role_names.should eq ["ROLE_FOO"]
  end

  def test_attributes : Nil
    token = TestToken.new
    token.attributes = {"foo" => %("bar")}

    token.attributes.should eq({"foo" => %("bar")})
    token.attribute("foo", String).should eq "bar"

    token.set_attribute "foo", "foo"
    token.attribute("foo", String).should eq "foo"

    token.set_attribute "scopes", ["read", "write"]
    token.attribute("scopes", Array(String)).should eq ["read", "write"]
    token.attributes.should eq({"foo" => %("foo"), "scopes" => %(["read","write"])})

    token.has_attribute?("foo").should be_true
    token.has_attribute?("oof").should be_false

    token.attribute?("foo", String).should eq "foo"
    token.attribute?("oof", String).should be_nil

    expect_raises ASEC::Exception::InvalidArgument, "This token has no 'foobar' attribute." do
      token.attribute "foobar", String
    end
  end

  def test_to_s : Nil
    TestToken.new(["A", "B"], ASEC::User::InMemory.new "foo", "").to_s.should eq %(TestToken(user="foo", roles="A, B"))
  end
end
