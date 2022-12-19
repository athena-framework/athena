require "./spec_helper"

struct ViewControllerTest < ATH::Spec::APITestCase
  def test_json_serializable_object : Nil
    self.get("/view/json").body.should eq %({"id":10,"name":"Bob"})
  end

  def test_json_serializable_array : Nil
    self.get("/view/json-array").body.should eq %([{"id":10,"name":"Bob"},{"id":20,"name":"Sally"}])
  end

  @[Pending]
  def test_json_serializable_nested_array : Nil
    self.get("/view//json-array-nested").body.should eq %([[{"id":10,"name":"Bob"}]])
  end

  def test_json_serializable_empty_array : Nil
    self.get("/view/json-array-empty").body.should eq %([])
  end

  def test_asr_serializable_object : Nil
    self.get("/view/asr").body.should eq %({"id":20})
  end

  def test_asr_serializable_array : Nil
    self.get("/view/asr-array").body.should eq %([{"id":10},{"id":20}])
  end

  def test_custom_status : Nil
    self.post("/view/status").status.accepted?.should be_true
  end

  def test_view : Nil
    response = self.get("/view")
    response.body.should eq %("DATA")
    response.status.should eq HTTP::Status::IM_A_TEAPOT
  end

  def test_view_json_serializable_array : Nil
    response = self.get("/view/array")
    response.body.should eq %([{"id":10,"name":"Bob"},{"id":20,"name":"Sally"}])
    response.status.should eq HTTP::Status::IM_A_TEAPOT
  end
end
