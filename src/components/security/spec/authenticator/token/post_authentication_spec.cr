require "../../spec_helper"

struct PostAuthenticationTokenTest < ASPEC::TestCase
  def test_new : Nil
    user = TestUser.new
    token = ASEC::Authenticator::Token::PostAuthentication.new user, "main", ["ROLE_USER"]

    token.user.should be user
    token.firewall_name.should eq "main"
    token.role_names.should eq ["ROLE_USER"]
  end

  def test_empty_firewall_name : Nil
    expect_raises ASEC::Exception::InvalidArgument, "The firewall name must not be empty." do
      ASEC::Authenticator::Token::PostAuthentication.new TestUser.new, "", [] of String
    end
  end
end
