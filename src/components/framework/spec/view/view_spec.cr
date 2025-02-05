require "../spec_helper"

struct ViewTest < ASPEC::TestCase
  def test_location : Nil
    url = "users"
    status = HTTP::Status::OK

    view = ATH::View.create_redirect url, status
    view.location.should eq url
    view.route.should be_nil
    view.response.status.should eq status

    view = ATH::View(Nil).new
    view.location = "bar"
    view.location.should eq "bar"
    view.route.should be_nil
  end

  def test_route : Nil
    route = "users"
    status = HTTP::Status::OK

    view = ATH::View.create_route_redirect route, status: status
    view.location.should be_nil
    view.route.should eq route
    view.response.status.should eq status

    view = ATH::View(Nil).new
    view.route = "bar"
    view.route.should eq "bar"
    view.location.should be_nil
  end

  @[DataProvider("data_provider")]
  def test_data(data) : Nil
    view = ATH::View(Hash(String, String | Int32)?).new
    view.data = data
    view.data.should eq data
  end

  def data_provider : Tuple
    {
      {nil},
      { {"foo" => "bar", "baz" => 10} },
    }
  end

  def test_format : Nil
    view = ATH::View(Nil).new
    view.format = "format"
    view.format.should eq "format"
  end

  def test_headers : Nil
    view = ATH::View(Nil).new
    view.headers = HTTP::Headers{"foo" => "bar"}

    headers = view.response.headers
    view.headers.has_key?("foo").should be_true
    headers["foo"].should eq "bar"

    view.set_header "string", "str"
    view.set_header "non-string", 10

    headers["string"].should eq "str"
    headers["non-string"].should eq "10"
  end

  def test_status : Nil
    view = ATH::View(Nil).new
    view.status = :not_found
    view.status.should eq HTTP::Status::NOT_FOUND
    view.response.status.should eq HTTP::Status::NOT_FOUND
  end

  def test_default_status_from_response : Nil
    view = ATH::View(Nil).new
    view.status.should be_nil
    view.response.status.should eq HTTP::Status::OK
  end
end
