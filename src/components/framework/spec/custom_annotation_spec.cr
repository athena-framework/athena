require "./spec_helper"

struct CustomAnnotationControllerTest < ATH::Spec::APITestCase
  def test_with_annotation : Nil
    self.get("/with-ann")

    self.assert_response_header_equals "ANNOTATION", "true"
    self.assert_response_header_equals "ANNOTATION_VALUE", "1"
  end

  def test_without_annotation : Nil
    self.get("/without-ann")

    self.assert_response_not_has_header "ANNOTATION"
    self.assert_response_header_equals "ANNOTATION_VALUE", "1"
  end

  def test_overriding_class_annotation : Nil
    headers = self.get("/with-ann-override").headers

    self.assert_response_not_has_header "ANNOTATION"
    self.assert_response_header_equals "ANNOTATION_VALUE", "2"
  end

  def test_top_level_parameter_ann : Nil
    self.get "/top-parameter-ann/10"
    self.assert_response_is_successful
  end

  def test_nested_level_parameter_ann : Nil
    self.get "/nested-parameter-ann/20"
    self.assert_response_is_successful
  end
end
