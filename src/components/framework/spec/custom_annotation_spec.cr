require "./spec_helper"

struct CustomAnnotationControllerTest < ATH::Spec::APITestCase
  def test_with_annotation : Nil
    headers = self.request("GET", "/with-ann").headers
    headers["ANNOTATION"]?.should eq "true"
    headers["ANNOTATION_VALUE"]?.should eq "1"
  end

  def test_without_annotation : Nil
    headers = self.request("GET", "/without-ann").headers
    headers["ANNOTATION"]?.should be_nil
    headers["ANNOTATION_VALUE"]?.should eq "1"
  end

  def test_overriding_class_annotation : Nil
    headers = self.request("GET", "/with-ann-override").headers
    headers["ANNOTATION"]?.should be_nil
    headers["ANNOTATION_VALUE"]?.should eq "2"
  end
end
