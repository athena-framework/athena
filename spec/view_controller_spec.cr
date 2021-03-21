require "./spec_helper"

struct ViewControllerTest < ART::Spec::APITestCase
  def test_json_serializable_object : Nil
    self.request("GET", "/view/json").body.should eq %({"id":10,"name":"Bob"})
  end

  def test_asr_serializable_object : Nil
    self.request("GET", "/view/asr").body.should eq %({"id":20})
  end

  def test_custom_status : Nil
    self.request("POST", "/view/status").status.accepted?.should be_true
  end
end
