require "./spec_helper"

struct SessionControllerTest < ATH::Spec::APITestCase
  def test_session_persists_across_requests : Nil
    self.get("/session/visits").body.should eq "1"
    self.assert_response_has_cookie "athena_session_id", path: "/"
    self.assert_browser_has_cookie "athena_session_id"

    self.get("/session/visits").body.should eq "2"
    self.assert_response_not_has_cookie "athena_session_id", path: "/"
  end

  def test_new_client_gets_a_new_session : Nil
    self.get("/session/visits").body.should eq "1"

    self.client.cookie_jar.clear

    self.get("/session/visits").body.should eq "1"
  end

  def test_session_is_resolved_for_nilable_parameters : Nil
    self.get("/session/optional").body.should eq "true"
  end

  def test_flash_messages_are_read_once : Nil
    self.post "/session/flash"

    self.get("/session/flash").body.should eq %(["Saved!"])
    self.get("/session/flash").body.should eq %([])
  end

  def test_flash_message_expectation : Nil
    self.post "/session/flash"

    self.assert_session_has_flash_message "notice"
    self.assert_session_has_flash_message "notice", "Saved!"
    self.assert_session_has_flash_message "notice", ["Other", "Saved!"]
  end

  def test_browser_session_is_used_by_requests : Nil
    session = self.client.session
    session.set "visits", 41
    session.save

    self.assert_browser_cookie_has_value "athena_session_id", session.id
    self.get("/session/visits").body.should eq "42"
  end

  def test_browser_session_has_the_data_of_requests : Nil
    self.get "/session/visits"

    self.client.session.get("visits", Int32).should eq 1
  end

  def test_browser_session_replaces_an_unknown_session_id : Nil
    self.client.cookie_jar.set ::HTTP::Cookie.new "athena_session_id", "a" * 32

    session = self.client.session

    session.id.should_not eq "a" * 32
    self.assert_browser_cookie_has_value "athena_session_id", session.id
  end

  def test_browser_session_sets_its_cookie_for_the_domains_of_cookies_with_its_name : Nil
    self.client.cookie_jar.set ::HTTP::Cookie.new "athena_session_id", "a" * 32, path: "/admin", domain: "example.com"

    session = self.client.session

    self.assert_browser_cookie_has_value "athena_session_id", session.id, domain: "example.com"
  end

  def test_invalidating_the_session_clears_its_cookie : Nil
    self.get "/session/visits"
    self.assert_browser_has_cookie "athena_session_id"

    self.post "/session/logout"
    self.assert_browser_not_has_cookie "athena_session_id"

    self.get("/session/visits").body.should eq "1"
  end

  def test_response_is_private_if_the_session_was_used : Nil
    self.get "/session/visits"

    self.assert_response_header_equals "cache-control", "private, max-age=0, must-revalidate"
    self.assert_response_has_header "expires"
  end

  def test_unused_session : Nil
    self.get("/session/unused").body.should eq %("unused")

    self.assert_response_not_has_cookie "athena_session_id", path: "/"
    self.assert_response_not_has_header "expires"
  end

  def test_session_used_by_a_stateless_route : Nil
    self.get "/session/stateless"

    self.assert_response_has_status :internal_server_error
    self.assert_response_header_equals "x-debug-exception-class", "Athena::HTTPKernel::Exception::UnexpectedSessionUsage"
  end
end
