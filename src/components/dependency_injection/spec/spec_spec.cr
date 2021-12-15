require "./spec_helper"

class FakeTransformer
  include TransformerInterface

  def transform
  end
end

class ADI::Spec::MockableServiceContainer
  setter reverse_transformer : TransformerInterface?
end

describe ADI::Spec::MockableServiceContainer do
  it "allows mocking services" do
    mock_container = ADI::Spec::MockableServiceContainer.new

    mock_container.reverse_transformer = FakeTransformer.new

    mock_container.reverse_transformer.should be_a FakeTransformer
  end
end
