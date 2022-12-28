require "../../../spec_helper"

struct AttributeEqualsExpectationTest < ASPEC::TestCase
  def test_match_valid : Nil
    request = new_request
    request.attributes.set "foo", "bar"

    ATH::Spec::Expectations::Request::AttributeEquals.new("foo", "bar").match(request).should be_true
  end

  def test_match_invalid : Nil
    request = new_request
    request.attributes.set "foo", "bar"

    ATH::Spec::Expectations::Request::AttributeEquals.new("foo", "baz").match(request).should be_false
    ATH::Spec::Expectations::Request::AttributeEquals.new("bar", "bar").match(request).should be_false
  end

  def test_failure_message : Nil
    ATH::Spec::Expectations::Request::AttributeEquals.new("foo", "bar")
      .failure_message(new_request)
      .should contain "Failed asserting that the request has attribute 'foo' with value 'bar'."
  end

  def test_failure_message_with_description : Nil
    ATH::Spec::Expectations::Request::AttributeEquals.new("foo", "bar", description: "Oh noes")
      .failure_message(new_request)
      .should contain "Oh noes\n\nFailed asserting that the request has attribute 'foo' with value 'bar'."
  end

  def test_negative_failure_message : Nil
    ATH::Spec::Expectations::Request::AttributeEquals.new("foo", "bar")
      .negative_failure_message(new_request)
      .should contain "Failed asserting that the request does not have attribute 'foo' with value 'bar'."
  end

  def test_negative_failure_message_with_description : Nil
    ATH::Spec::Expectations::Request::AttributeEquals.new("foo", "bar", description: "Oh noes")
      .negative_failure_message(new_request)
      .should contain "Oh noes\n\nFailed asserting that the request does not have attribute 'foo' with value 'bar'."
  end
end
