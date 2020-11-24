require "./spec_helper"

struct ParamTest < ART::Spec::APITestCase
  def test_optional_query_param_provided : Nil
    self.request("GET", "/query?search=blah").body.should eq %("blah")
  end

  def test_optional_query_param_missing : Nil
    self.request("GET", "/query").body.should eq %({"code":400,"message":"Parameter 'search' of value '' violated a constraint: 'This value should not be null.'\\n"})
  end

  def test_required_regex_query_param_provided : Nil
    self.request("GET", "/query/page?page=10").body.should eq %(10)
  end

  def test_required_regex_query_param_invalid : Nil
    response = self.request("GET", "/query/page?page=foo")
    response.status.should eq HTTP::Status::BAD_REQUEST
    response.body.should eq %({"code":400,"message":"Required parameter 'page' with value 'foo' could not be converted into a valid 'Int32'."})
  end

  def test_required_regex_query_param_missing : Nil
    self.request("GET", "/query/page").body.should eq %(5)
  end

  def test_nilable_regex_query_param_provided : Nil
    self.request("GET", "/query/page-nilable?page=10").body.should eq %(10)
  end

  def test_nilable_regex_query_param_invalid : Nil
    response = self.request("GET", "/query/page-nilable?page=foo")
    response.status.should eq HTTP::Status::OK
    response.body.should eq %(null)
  end

  def test_nilable_regex_query_param_missing : Nil
    response = self.request("GET", "/query/page-nilable")
    response.status.should eq HTTP::Status::OK
    response.body.should eq %(null)
  end

  def test_nilable_strict_regex_query_param_provided : Nil
    self.request("GET", "/query/page-nilable-strict?page=10").body.should eq %(10)
  end

  def test_nilable_strict_regex_query_param_invalid_type : Nil
    response = self.request("GET", "/query/page-nilable-strict?page=foo")
    response.status.should eq HTTP::Status::BAD_REQUEST
    response.body.should eq %({"code":400,"message":"Required parameter 'page' with value 'foo' could not be converted into a valid '(Int32 | Nil)'."})
  end

  def test_nilable_strict_regex_query_param_invalid_value : Nil
    response = self.request("GET", "/query/page-nilable-strict?page=20")
    response.status.should eq HTTP::Status::BAD_REQUEST
    response.body.should eq %({"code":400,"message":"Parameter 'page' of value '20' violated a constraint: 'Parameter 'page' value does not match requirements '(?-imsx:1\\\\d)''\\n"})
  end

  def test_nilable_strict_regex_query_param_missing : Nil
    response = self.request("GET", "/query/page-nilable-strict")
    response.status.should eq HTTP::Status::OK
    response.body.should eq %(null)
  end

  def test_annotation_query_param_valid : Nil
    self.request("GET", "/query/annotation?search=foo").body.should eq %("foo")
  end

  def test_annotation_query_param_invalid : Nil
    response = self.request("GET", "/query/annotation?search=")
    response.status.should eq HTTP::Status::BAD_REQUEST
    response.body.should eq %({"code":400,"message":"Parameter 'search' of value '' violated a constraint: 'This value should not be blank.'\\n"})
  end

  def test_annotation_array_valid : Nil
    self.request("GET", "/query/ids?ids=3.14&ids=0.0").body.should eq %([3.14,0.0])
  end

  def test_annotation_array_invalid : Nil
    response = self.request("GET", "/query/ids?ids=3.14&ids=-2.5")
    response.status.should eq HTTP::Status::BAD_REQUEST
    response.body.should eq %({"code":400,"message":"Parameter 'ids[1]' of value '-2.5' violated a constraint: 'This value should be positive or zero.'\\nParameter 'ids[1]' of value '-2.5' violated a constraint: 'This value should be between -1.0 and 10.'\\n"})
  end

  def test_param_converter_class : Nil
  end

  def test_param_converter_named_tuple : Nil
  end

  def test_incompatible_params_one : Nil
    self.request("GET", "/query/searchv1?search=foo").body.should eq %("foo")
  end

  def test_incompatible_params_other : Nil
    self.request("GET", "/query/searchv1?by_author=author").body.should eq %("author")
  end

  def test_incompatible_params_both : Nil
    response = self.request("GET", "/query/searchv1?search=foo&by_author=bar")
    response.status.should eq HTTP::Status::BAD_REQUEST
    response.body.should eq %({"code":400,"message":"Parameter 'by_author' is incompatible with parameter 'search'."})
  end

  def test_request_param : Nil
  end
end
