require "../../../spec_helper"

struct PasswordCredentialsTest < ASPEC::TestCase
  def test_mark_resolved_erases_the_password : Nil
    credentials = ASEC::Authenticator::Passport::Credentials::Password.new "password"

    credentials.resolved?.should be_false
    credentials.password.should eq "password"

    credentials.mark_resolved

    credentials.resolved?.should be_true

    expect_raises ASEC::Exception::Logic, "The credentials are erased as another listener already verified these credentials." do
      credentials.password
    end
  end
end
