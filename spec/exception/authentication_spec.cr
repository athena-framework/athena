require "../spec_helper"

struct AuthenticationExceptionTest < ASPEC::TestCase
  def test_defaults : Nil
    ex = ASEC::Exception::Authentication.new "Internal message."

    ex.message_key.should eq "An authentication exception occurred."
    ex.message_data.should be_empty
    ex.token.should be_nil
  end

  def test_token : Nil
    token = TestToken.new
    ex = ASEC::Exception::Authentication.new
    ex.token = token

    ex.token.should be token
  end

  def test_user_not_found : Nil
    ex = ASEC::Exception::UserNotFound.new "Internal message.", user_identifier: "fabien"

    ex.message_key.should eq "Username could not be found."
    ex.message_data.should eq({"{{ username }}" => "fabien", "{{ user_identifier }}" => "fabien"})
  end

  def test_user_not_found_without_identifier : Nil
    ASEC::Exception::UserNotFound.new.message_data.should eq({"{{ username }}" => "", "{{ user_identifier }}" => ""})
  end

  def test_authentication_service : Nil
    ASEC::Exception::UnsupportedUser.new.message_key.should eq "Authentication request could not be processed due to a system problem."
  end

  def test_access_denied : Nil
    ex = ASEC::Exception::AccessDenied.new

    ex.message.should eq "Access Denied."
    ex.attribute.should be_nil
    ex.access_decision.should be_nil
  end
end
