require "./spec_helper"

struct ParamConverterControllerTest < ATH::Spec::APITestCase
  def test_happy_path : Nil
    self.request("POST", "/param-converter").body.should eq "1"
  end

  def test_single_additional_generic : Nil
    self.request("POST", "/param-converter/single-additional").body.should eq "2"
  end

  def test_multiple_additional_generic : Nil
    self.request("POST", "/param-converter/multiple-additional").body.should eq "4"
  end
end
