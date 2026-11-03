require "../../../spec_helper"

struct CustomCredentialsTest < ASPEC::TestCase
  def test_valid_credentials : Nil
    user = TestUser.new "api_user"
    checked = [] of {String, ASEC::User::Interface}

    credentials = ASEC::Authenticator::Passport::Credentials::Custom.new("token") do |token, checked_user|
      checked << {token, checked_user}

      true
    end

    credentials.resolved?.should be_false

    credentials.execute_custom_checker user

    credentials.resolved?.should be_true
    checked.should eq [{"token", user}]
  end

  def test_invalid_credentials : Nil
    credentials = ASEC::Authenticator::Passport::Credentials::Custom.new({"password" => "foo"}) { false }

    expect_raises ASEC::Exception::BadCredentials, "Credentials check failed as the block passed to 'ASEC::Authenticator::Passport::Credentials::Custom' did not return 'true'." do
      credentials.execute_custom_checker TestUser.new
    end

    credentials.resolved?.should be_false
  end
end
