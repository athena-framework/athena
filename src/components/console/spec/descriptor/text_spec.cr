require "../spec_helper"
require "./abstract_descriptor_test_case"

struct TextDescriptorTest < AbstractDescriptorTestCase
  # TODO: Include test data for double width chars
  # For both Application and Command contexts

  def test_describe_application_filtered_namespace : Nil
    self.assert_description(
      File.read("#{__DIR__}/../fixtures/text/application_filtered_namespace.txt"),
      DescriptorApplication2.new,
      ACON::Descriptor::Context.new(namespace: "command4"),
    )
  end

  protected def descriptor : ACON::Descriptor::Interface
    ACON::Descriptor::Text.new
  end

  protected def format : String
    "txt"
  end
end
