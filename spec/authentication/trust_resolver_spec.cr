require "../spec_helper"

struct TrustResolverTest < ASPEC::TestCase
  def test_authenticated : Nil
    resolver = ASEC::Authentication::TrustResolver.new

    resolver.authenticated?(nil).should be_false
    resolver.authenticated?(ASEC::Authentication::Token::Null.new).should be_false
    resolver.authenticated?(TestToken.new).should be_false
    resolver.authenticated?(TestToken.new user: TestUser.new).should be_true
  end

  def test_full_fledged : Nil
    resolver = ASEC::Authentication::TrustResolver.new

    resolver.full_fledged?(nil).should be_false
    resolver.full_fledged?(ASEC::Authentication::Token::Null.new).should be_false
    resolver.full_fledged?(TestToken.new user: TestUser.new).should be_true
  end
end
