require "./spec_helper"

struct RoutingTest < ART::Spec::APITestCase
  def test_is_concurrently_safe : Nil
    spawn do
      sleep 1
      self.request("GET", "/get/safe?bar").body.should eq %("safe")
    end
    self.request("GET", "/get/safe?foo").body.should eq %("safe")
  end

  def test_does_not_reuse_container_with_keep_alive_connections : Nil
    response1 = self.request("GET", "/container/id", headers: HTTP::Headers{"connection" => "keep-alive"}).body

    self.init_container

    response2 = self.request("GET", "/container/id", headers: HTTP::Headers{"connection" => "keep-alive"}).body

    response1.should_not eq response2
  end

  def test_route_doesnt_exist : Nil
    response = self.request "GET", "/fake/route"
    response.status.should eq HTTP::Status::NOT_FOUND
    response.body.should eq %({"code":404,"message":"No route found for 'GET /fake/route'"})
  end

  def test_invalid_method : Nil
    response = self.request "POST", "/art/response"
    response.status.should eq HTTP::Status::METHOD_NOT_ALLOWED
    response.body.should eq %({"code":405,"message":"No route found for 'POST /art/response': (Allow: GET)"})
  end

  def test_allows_returning_an_athena_response : Nil
    response = self.request "GET", "/art/response"
    response.status.should eq HTTP::Status::IM_A_TEAPOT
    response.headers["content-type"].should eq "BAR"
    response.body.should eq "FOO"
  end

  def test_it_supports_redirects : Nil
    response = self.request "GET", "/art/redirect"
    response.status.should eq HTTP::Status::FOUND
    response.headers["location"].should eq "https://crystal-lang.org"
    response.body.should be_empty
  end

  def test_it_supports_custom_http_methods : Nil
    self.request("FOO", "/custom-method").body.should eq %("FOO")
  end

  def test_custom_response_status_get : Nil
    response = self.request "GET", "/custom-status"
    response.status.should eq HTTP::Status::ACCEPTED
  end

  def test_custom_response_status_head : Nil
    response = self.request "HEAD", "/custom-status"
    response.status.should eq HTTP::Status::ACCEPTED
  end

  def test_works_with_param_converters : Nil
    self.request "GET", "/events"
    self.request "GET", "/events?since=2020-04-08T12:34:56Z"
  end

  def test_macro_dsl_nil_return_type : Nil
    response = self.request "GET", "/macro/get-nil"
    response.status.should eq HTTP::Status::NO_CONTENT
    response.body.should be_empty
  end

  def test_macro_dsl_with_arguments : Nil
    self.request("GET", "/macro/add/50/25").body.should eq "75"
  end

  def test_macro_dsl_get : Nil
    response = self.request "GET", "/macro"
    response.status.should eq HTTP::Status::OK
    response.body.should eq %("GET")
  end

  def test_macro_dsl_head : Nil
    response = self.request "HEAD", "/macro"
    response.status.should eq HTTP::Status::OK
  end

  {% for method in ["POST", "PUT", "PATCH", "DELETE", "LINK", "UNLINK"] %}
    def test_macro_dsl_{{method.downcase.id}} : Nil
      self.request({{method}}, "/macro").body.should eq %({{method}})
    end
  {% end %}

  def test_constraints_404_if_no_match : Nil
    response = self.request "GET", "/macro/bar"
    response.status.should eq HTTP::Status::NOT_FOUND
    response.body.should eq %({"code":404,"message":"No route found for 'GET /macro/bar'"})
  end

  def test_constraints_routes_if_match : Nil
    self.request("GET", "/macro/foo").body.should eq %("foo")
  end

  def test_generate_url_no_args : Nil
    self.request("GET", "/url").body.should eq %("/art/response")
  end

  def test_generate_url_hash : Nil
    self.request("GET", "/url-hash").body.should eq %("/art/response?id=10")
  end

  def test_generate_url_named_tuple : Nil
    self.request("GET", "/url-nt").body.should eq %("/art/response?id=10")
  end

  def test_generate_url_named_tuple_abso : Nil
    self.request("GET", "/url-nt-abso").body.should eq %("https://localhost/art/response?id=10")
  end

  def test_redirect_to_route : Nil
    response = self.request("GET", "/redirect-url")
    response.status.should eq HTTP::Status::FOUND
    response.headers["location"].should eq "/art/response"
  end

  def test_redirect_to_route_status : Nil
    response = self.request("GET", "/redirect-url-status")
    response.status.should eq HTTP::Status::PERMANENT_REDIRECT
    response.headers["location"].should eq "/art/response"
  end

  def test_redirect_to_route_hash : Nil
    response = self.request("GET", "/redirect-url-hash")
    response.status.should eq HTTP::Status::FOUND
    response.headers["location"].should eq "/art/response?id=10"
  end

  def test_redirect_to_route_nt : Nil
    response = self.request("GET", "/redirect-url-nt")
    response.status.should eq HTTP::Status::FOUND
    response.headers["location"].should eq "/art/response?id=10"
  end
end
