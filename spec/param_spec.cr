require "./spec_helper"

struct ParamTest < ATH::Spec::APITestCase
  def test_required_query_param_provided : Nil
    self.request("GET", "/query?search=blah").body.should eq %("blah")
  end

  def test_required_query_param_missing : Nil
    self.request("GET", "/query").body.should eq %({"code":422,"message":"Parameter 'search' is invalid.","errors":[{"property":"search","message":"This value should not be null.","code":"c7e77b14-744e-44c0-aa7e-391c69cc335c"}]})
  end

  def test_regex_query_param_provided_with_default : Nil
    self.request("GET", "/query/page?page=10").body.should eq %(10)
  end

  def test_regex_query_param_invalid_with_default : Nil
    response = self.request("GET", "/query/page?page=foo")
    response.status.should eq HTTP::Status::BAD_REQUEST
    response.body.should eq %({"code":400,"message":"Required parameter 'page' with value 'foo' could not be converted into a valid 'Int32'."})
  end

  def test_regex_query_param_missing_with_default : Nil
    self.request("GET", "/query/page").body.should eq %(5)
  end

  def test_nilable_not_strict_regex_query_param_provided : Nil
    self.request("GET", "/query/page-nilable?page=10").body.should eq %(10)
  end

  def test_nilable_not_strict_regex_query_param_invalid : Nil
    self.request("GET", "/query/page-nilable?page=foo").body.should eq %(null)
  end

  def test_nilable_not_strict_regex_query_param_missing : Nil
    self.request("GET", "/query/page-nilable").body.should eq %(null)
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
    response.status.should eq HTTP::Status::UNPROCESSABLE_ENTITY
    response.body.should eq %({"code":422,"message":"Parameter 'page' is invalid.","errors":[{"property":"page","message":"Parameter 'page' value does not match requirements: (?-imsx:^(?-imsx:1\\\\d)$)","code":"108987a0-2d81-44a0-b8d4-1c7ab8815343"}]})
  end

  def test_nilable_strict_regex_query_param_missing : Nil
    self.request("GET", "/query/page-nilable-strict").body.should eq %(null)
  end

  def test_annotation_query_param_valid : Nil
    self.request("GET", "/query/annotation?search=foo").body.should eq %("foo")
  end

  def test_annotation_query_param_invalid : Nil
    response = self.request("GET", "/query/annotation?search=")
    response.status.should eq HTTP::Status::UNPROCESSABLE_ENTITY
    response.body.should eq %({"code":422,"message":"Parameter 'search' is invalid.","errors":[{"property":"search","message":"This value should not be blank.","code":"0d0c3254-3642-4cb0-9882-46ee5918e6e3"}]})
  end

  def test_annotation_array_valid : Nil
    self.request("GET", "/query/ids?ids=3.14&ids=0.0").body.should eq %([3.14,0.0])
  end

  def test_annotation_array_invalid : Nil
    response = self.request("GET", "/query/ids?ids=3.14&ids=-2.5")
    response.status.should eq HTTP::Status::UNPROCESSABLE_ENTITY
    response.body.should eq %({"code":422,"message":"Parameter 'ids' is invalid.","errors":[{"property":"ids[1]","message":"This value should be positive or zero.","code":"e09e52d0-b549-4ba1-8b4e-420aad76f0de"},{"property":"ids[1]","message":"This value should be between -1.0 and 10.","code":"7e62386d-30ae-4e7c-918f-1b7e571c6d69"}]})
  end

  def test_param_converter_class : Nil
    self.request("GET", "/query/time?time=2020-04-07T12:34:56Z").body.should eq %("Today is: 2020-04-07 12:34:56 UTC")
  end

  def test_param_converter_class_single_generic : Nil
    self.request("GET", "/query/generic/single").body.should eq "1"
  end

  def test_param_converter_class_single_additional_generic : Nil
    self.request("GET", "/query/generic/single-additional").body.should eq "2"
  end

  def test_param_converter_class_multiple_additional_generic : Nil
    self.request("GET", "/query/generic/multiple-additional").body.should eq "4"
  end

  def test_param_converter_default_missing : Nil
    self.request("GET", "/query/time").body.should eq %("Today is: 2020-10-01 00:00:00 UTC")
  end

  def test_param_converter_named_tuple : Nil
    self.request("GET", "/query/nt_time?time=2020--10//20  12:34:56").body.should eq %("Today is: 2020-10-20 12:34:56 UTC")
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
    self.request(
      "POST",
      "/query/login",
      "username=George&password=abc123"
    ).body.should eq %("R2VvcmdlOmFiYzEyMw==")
  end
end
