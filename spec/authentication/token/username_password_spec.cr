require "../../spec_helper"

struct UsernamePasswordTokenTest < ASPEC::TestCase
  def test_initialize : Nil
    user = ASEC::User::InMemory.new "foo", "bar", ["ROLE_FOO"]
    token = ASEC::Authentication::Token::UsernamePassword.new user, "key", ["ROLE_FOO"]

    token.role_names.should eq ["ROLE_FOO"]
    token.firewall_name.should eq "key"
    token.user.should be user
  end

  def test_empty_firewall_name : Nil
    expect_raises ASEC::Exception::InvalidArgument, "The firewall name must not be empty." do
      ASEC::Authentication::Token::UsernamePassword.new TestUser.new, ""
    end
  end

  def test_to_s : Nil
    token = ASEC::Authentication::Token::UsernamePassword.new ASEC::User::InMemory.new("foo", "", ["A", "B"]), "foo", ["A", "B"]

    token.to_s.should eq %(UsernamePassword(user="foo", roles="A, B"))
  end
end
