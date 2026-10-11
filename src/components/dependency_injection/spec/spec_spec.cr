require "./spec_helper"

module TransformerInterface
  abstract def transform
end

class FakeTransformer
  include TransformerInterface

  def transform
  end
end

class ADI::Spec::MockableServiceContainer
  property reverse_transformer : TransformerInterface?
end

describe ADI::Spec::MockableServiceContainer do
  it "allows mocking services" do
    mock_container = ADI::Spec::MockableServiceContainer.new

    mock_container.reverse_transformer = FakeTransformer.new

    mock_container.reverse_transformer.should be_a FakeTransformer
  end
end

@[ADI::Register]
class ContainerTestCaseCloseable
  include ACTR::Service::Closeable

  class_getter closes = 0

  def close : Nil
    @@closes += 1
  end
end

@[ASPEC::TestCase::Skip]
private struct MockContainerTestCase < ADI::Spec::ContainerTestCase; end

describe ADI::Spec::ContainerTestCase do
  it "gives each test its own container" do
    first = MockContainerTestCase.new.container
    second = MockContainerTestCase.new.container

    first.should_not be second
  end

  describe "#container" do
    it "returns the container of the current fiber" do
      MockContainerTestCase.new.container.should be ADI.container
    end
  end

  describe "#tear_down" do
    it "closes closeable services" do
      closes = ContainerTestCaseCloseable.closes

      MockContainerTestCase.new.tear_down

      ContainerTestCaseCloseable.closes.should eq closes + 1
    end
  end
end
