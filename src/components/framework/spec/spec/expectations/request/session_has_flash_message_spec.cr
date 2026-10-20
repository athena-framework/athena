require "../../../spec_helper"

struct SessionHasFlashMessageExpectationTest < ASPEC::TestCase
  def test_match_valid : Nil
    request = self.request_with_flashes

    ATH::Spec::Expectations::Request::SessionHasFlashMessage.new("notice").match(request).should be_true
    ATH::Spec::Expectations::Request::SessionHasFlashMessage.new("notice", ["Saved!"]).match(request).should be_true
    ATH::Spec::Expectations::Request::SessionHasFlashMessage.new("notice", ["Other", "Updated!"]).match(request).should be_true
  end

  def test_match_invalid : Nil
    request = self.request_with_flashes

    ATH::Spec::Expectations::Request::SessionHasFlashMessage.new("error").match(request).should be_false
    ATH::Spec::Expectations::Request::SessionHasFlashMessage.new("notice", ["Other"]).match(request).should be_false
    ATH::Spec::Expectations::Request::SessionHasFlashMessage.new("notice").match(new_request).should be_false
    ATH::Spec::Expectations::Request::SessionHasFlashMessage.new("notice").match("foo").should be_false
  end

  def test_failure_message : Nil
    ATH::Spec::Expectations::Request::SessionHasFlashMessage.new("notice")
      .failure_message(self.request_with_flashes)
      .should eq "Failed asserting that the session has flash message of type 'notice'."
  end

  def test_failure_message_with_messages : Nil
    ATH::Spec::Expectations::Request::SessionHasFlashMessage.new("notice", ["Saved!", "Updated!"])
      .failure_message(self.request_with_flashes)
      .should eq "Failed asserting that the session has flash message of type 'notice' containing: Saved!, Updated!."
  end

  def test_failure_message_without_session : Nil
    ATH::Spec::Expectations::Request::SessionHasFlashMessage.new("notice")
      .failure_message(new_request)
      .should eq "Failed asserting that the session has flash message of type 'notice', because the request does not have a session."
  end

  def test_failure_message_with_description : Nil
    ATH::Spec::Expectations::Request::SessionHasFlashMessage.new("notice", description: "Oh noes")
      .failure_message(self.request_with_flashes)
      .should eq "Oh noes\n\nFailed asserting that the session has flash message of type 'notice'."
  end

  private def request_with_flashes : AHTTP::Request
    session = AHTTP::Session.new AHTTP::Session::Storage.new AHTTP::Session::Storage::Handler::Memory.new
    session.flash_bag.add "notice", "Saved!"
    session.flash_bag.add "notice", "Updated!"

    request = new_request
    request.session = session
    request
  end
end
