require "../spec_helper"

struct AbstractAuthenticatorTest < ASPEC::TestCase
  def test_create_token : Nil
    user = TestUser.new "wouter", ["ROLE_ADMIN"]
    passport = ASEC::Authenticator::Passport::SelfValidating.new ASEC::Authenticator::Passport::Badge::User.new("wouter") { user }

    token = MockAuthenticator.new.create_token passport, "main"

    token = token.should be_a ASEC::Authenticator::Token::PostAuthentication
    token.user.should be user
    token.firewall_name.should eq "main"
    token.role_names.should eq ["ROLE_ADMIN"]
  end
end
