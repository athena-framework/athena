require "./spec_helper"

struct RoutingTest < ATH::Spec::APITestCase
  def test_is_concurrently_safe : Nil
    spawn do
      sleep 100.milliseconds
      self.get("/get/safe?bar").body.should eq %("safe")
    end
    self.get("/get/safe?foo").body.should eq %("safe")
  end

  def test_head_request : Nil
    response = self.head "/head"
    response.status.should eq HTTP::Status::OK
    response.body.should be_empty
    response.headers["content-length"].should eq "6" # JSON encoding adds 2 extra `"` chars
  end

  def test_head_request_on_get_endpoint : Nil
    response = self.head "/get-head"
    response.status.should eq HTTP::Status::OK
    response.body.should be_empty
    response.headers["FOO"].should eq "BAR"           # Actually runs the controller action code
    response.headers["content-length"].should eq "10" # JSON encoding adds 2 extra `"` chars
  end

  def test_does_not_reuse_container_with_keep_alive_connections : Nil
    response1 = self.get("/container/id", headers: HTTP::Headers{"connection" => "keep-alive"}).body

    self.init_container

    response2 = self.get("/container/id", headers: HTTP::Headers{"connection" => "keep-alive"}).body

    response1.should_not eq response2
  end

  def test_route_doesnt_exist : Nil
    response = self.get "/fake/route"
    response.status.should eq HTTP::Status::NOT_FOUND
    response.body.should eq %({"code":404,"message":"No route found for 'GET /fake/route'."})
  end

  def test_route_doesnt_exist_with_referrer : Nil
    # This is misspelled on purpose, see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referer.
    response = self.get "/fake/route", headers: HTTP::Headers{"referer" => "somebody"} # spellchecker:disable-line
    response.status.should eq HTTP::Status::NOT_FOUND
    response.body.should eq %({"code":404,"message":"No route found for 'GET /fake/route' (from: 'somebody')."})
  end

  def test_invalid_method : Nil
    response = self.post "/art/response"
    response.status.should eq HTTP::Status::METHOD_NOT_ALLOWED
    response.body.should eq %({"code":405,"message":"No route found for 'POST /art/response': Method Not Allowed (Allow: GET)."})
  end

  def test_allows_returning_an_athena_response : Nil
    response = self.get "/art/response"
    response.status.should eq HTTP::Status::IM_A_TEAPOT
    response.headers["content-type"].should eq "BAR"
    response.headers["content-length"].should eq "3"
    response.headers.has_key?("transfer-encoding").should be_false
    response.body.should eq "FOO"
  end

  def test_allows_returning_a_streamed_response : Nil
    response = self.get "/art/streamed-response"
    response.status.should eq HTTP::Status::IM_A_TEAPOT
    response.headers["content-type"].should eq "BAR"
    response.headers.has_key?("content-length").should be_false
    response.headers["transfer-encoding"].should eq "chunked"
    response.body.should eq %("FOO")
  end

  def test_it_supports_redirects : Nil
    response = self.get "/art/redirect"
    response.status.should eq HTTP::Status::FOUND
    response.headers["location"].should eq "https://crystal-lang.org"
    response.body.should be_empty
  end

  def test_it_supports_custom_http_methods : Nil
    self.request("FOO", "/custom-method").body.should eq %("FOO")
  end

  def test_custom_response_status_get : Nil
    self.get "/custom-status"

    self.assert_response_has_status :accepted
  end

  def test_custom_response_status_head : Nil
    self.head "/custom-status"

    self.assert_response_has_status :accepted
  end

  def test_uses_default_value_if_no_other_value_provided : Nil
    self.get("/default").body.should eq "10"
  end

  def test_uses_nil_if_no_other_value_provided_and_is_nilable : Nil
    self.get("/nilable").body.should eq "null"
  end

  def test_macro_dsl_nil_return_type : Nil
    response = self.get "/macro/get-nil"
    response.status.should eq HTTP::Status::NO_CONTENT
    response.body.should be_empty
  end

  def test_macro_dsl_with_arguments : Nil
    self.get("/macro/add/50/25").body.should eq "75"
  end

  def test_macro_dsl_get : Nil
    response = self.get "/macro"
    response.status.should eq HTTP::Status::OK
    response.body.should eq %("GET")
  end

  def test_macro_dsl_head : Nil
    response = self.head "/macro"
    response.status.should eq HTTP::Status::OK
    response.body.should be_empty
  end

  {% for method in ["POST", "PUT", "PATCH", "DELETE", "LINK", "UNLINK"] %}
    def test_macro_dsl_{{method.downcase.id}} : Nil
      self.request({{method}}, "/macro").body.should eq %({{method}})
    end
  {% end %}

  def test_get_helper_method : Nil
    self.get("/macro").body.should eq %("GET")
  end

  def test_post_helper_method : Nil
    self.post("/macro").body.should eq %("POST")
    self.post("/echo", "BODY").body.should eq %("BODY")
  end

  def test_put_helper_method : Nil
    self.put("/macro").body.should eq %("PUT")
    self.put("/echo", "BODY").body.should eq %("BODY")
  end

  def test_delete_helper_method : Nil
    self.delete("/macro").body.should eq %("DELETE")
  end

  def test_athena_request : Nil
    self.request(ATH::Request.new("GET", "/macro")).body.should eq %("GET")
  end

  def test_http_request : Nil
    self.request(HTTP::Request.new("GET", "/macro")).body.should eq %("GET")
  end

  def test_constraints_404_if_no_match : Nil
    response = self.get "/macro/bar"
    response.status.should eq HTTP::Status::NOT_FOUND
    response.body.should eq %({"code":404,"message":"No route found for 'GET /macro/bar'."})
  end

  def test_constraints_routes_if_match : Nil
    self.get("/macro/foo").body.should eq %("foo")
  end

  def test_generate_url_no_args : Nil
    self.get("/url").body.should eq %("/art/response")
  end

  def test_generate_url_hash : Nil
    self.get("/url-hash").body.should eq %("/art/response?id=10")
  end

  def test_generate_url_named_tuple : Nil
    self.get("/url-nt").body.should eq %("/art/response?id=10")
  end

  def test_generate_url_named_tuple_abso : Nil
    self.get("/url-nt-abso", headers: HTTP::Headers{"host" => "crystal-lang.org"}).body.should eq %("http://crystal-lang.org/art/response?id=10")
  end

  def test_redirect_to_route : Nil
    self.get "/redirect-url"

    self.assert_response_redirects "/art/response", :found
  end

  def test_redirect_to_route_status : Nil
    self.get "/redirect-url-status"

    self.assert_response_redirects "/art/response", :permanent_redirect
  end

  def test_redirect_to_route_hash : Nil
    self.get "/redirect-url-hash"

    self.assert_response_redirects "/art/response?id=10", :found
  end

  def test_redirect_to_route_nt : Nil
    self.get "/redirect-url-nt"

    self.assert_response_redirects "/art/response?id=10", :found
  end

  def test_using_route_handler_directly_with_http_request : Nil
    response = self.client.container.athena_route_handler.handle HTTP::Request.new "GET", "/art/response"
    response.status.should eq HTTP::Status::IM_A_TEAPOT
    response.content.should eq "FOO"
  end

  def test_applies_cookies_to_actual_response : Nil
    self.get "/cookies"

    self.assert_cookie_has_value "key", "value"
  end

  def test_redirects_get_request_to_route_without_trailing_slash : Nil
    self.get "/macro/get-nil/", headers: HTTP::Headers{"host" => "localhost"}

    self.assert_response_redirects "http://localhost/macro/get-nil"
  end

  def test_redirects_head_request_to_route_without_trailing_slash : Nil
    self.head "/head/", headers: HTTP::Headers{"host" => "localhost"}

    self.assert_response_redirects "http://localhost/head"
  end

  def test_redirects_get_request_to_route_with_trailing_slash : Nil
    self.get "/head-get", headers: HTTP::Headers{"host" => "localhost"}

    self.assert_response_redirects "http://localhost/head-get/"
  end

  def test_redirects_head_request_to_route_with_trailing_slash : Nil
    self.head "/head-get", headers: HTTP::Headers{"host" => "localhost"}

    self.assert_response_redirects "http://localhost/head-get/"
  end

  def test_does_not_redirect_post_requests : Nil
    self.post "/art/response/"

    self.assert_response_has_status :not_found
  end
end
