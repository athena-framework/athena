require "../../spec_helper"

struct NullTokenTest < ASPEC::TestCase
  def test_values : Nil
    token = ASEC::Authentication::Token::Null.new

    token.user.should be_nil
    token.user_identifier.should be_empty
    token.role_names.should be_empty
    token.attributes.should be_empty
    token.has_attribute?("foo").should be_false
    token.attribute?("foo", String).should be_nil
    token.to_s.should be_empty
  end

  def test_attribute : Nil
    expect_raises ASEC::Exception::InvalidArgument, "This token has no 'foo' attribute." do
      ASEC::Authentication::Token::Null.new.attribute "foo", String
    end
  end

  def test_set_user : Nil
    expect_raises ASEC::Exception::Logic, "Cannot set user on a null token." do
      ASEC::Authentication::Token::Null.new.user = TestUser.new
    end
  end

  def test_set_attributes : Nil
    expect_raises ASEC::Exception::Logic, "Cannot set attributes of a null token." do
      ASEC::Authentication::Token::Null.new.attributes = {"foo" => %("bar")}
    end
  end

  def test_set_attribute : Nil
    expect_raises ASEC::Exception::Logic, "Cannot add attribute to a null token." do
      ASEC::Authentication::Token::Null.new.set_attribute "foo", "bar"
    end
  end
end
