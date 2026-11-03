require "../spec_helper"

struct CustomUserMessageAuthenticationTest < ASPEC::TestCase
  def test_initialize_with_safe_message : Nil
    ex = ASEC::Exception::CustomUserMessageAuthentication.new "SAFE MESSAGE", {"foo" => "bar"}

    ex.message.should eq "SAFE MESSAGE"
    ex.message_key.should eq "SAFE MESSAGE"
    ex.message_data.should eq({"foo" => "bar"})
  end

  def test_set_safe_message : Nil
    ex = ASEC::Exception::CustomUserMessageAuthentication.new "INTERNAL MESSAGE"
    ex.set_safe_message "SAFE MESSAGE", {"foo" => "bar"}

    ex.message.should eq "INTERNAL MESSAGE"
    ex.message_key.should eq "SAFE MESSAGE"
    ex.message_data.should eq({"foo" => "bar"})
  end

  def test_account_status : Nil
    user = TestUser.new
    ex = ASEC::Exception::CustomUserMessageAccountStatus.new "SAFE MESSAGE", {"foo" => "bar"}, user: user

    ex.message_key.should eq "SAFE MESSAGE"
    ex.message_data.should eq({"foo" => "bar"})
    ex.user.should be user

    ex.set_safe_message "OTHER MESSAGE"
    ex.message_key.should eq "OTHER MESSAGE"
    ex.message_data.should be_empty
  end
end
