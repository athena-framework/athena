require "../spec_helper"

ADI.configuration_annotation IsActiveProperty, active : Bool = true

private struct ActivePropertyExclusionStrategy
  include Athena::Serializer::ExclusionStrategies::ExclusionStrategyInterface

  # :inherit:
  def skip_property?(metadata : ASR::PropertyMetadataBase, context : ASR::Context) : Bool
    return false if context.direction.deserialization?

    ann_configs = metadata.annotation_configurations

    ann_configs.has?(IsActiveProperty) && !ann_configs[IsActiveProperty].active
  end
end

# Mainly testing `Athena::Config` integration in regards to custom annotations accessible via the property metadata.
describe ActivePropertyExclusionStrategy do
  describe "#skip_property?" do
    describe :deserialization do
      it "it should not skip" do
        ActivePropertyExclusionStrategy.new.skip_property?(create_metadata, ASR::DeserializationContext.new).should be_false
      end
    end

    describe :serialization do
      describe "without the annotation" do
        it "should not skip" do
          ActivePropertyExclusionStrategy.new.skip_property?(create_metadata, ASR::SerializationContext.new).should be_false
        end
      end

      describe "with the annotation" do
        it true do
          ann_config = ADI::AnnotationConfigurations.new({IsActiveProperty => [IsActivePropertyConfiguration.new] of ADI::AnnotationConfigurations::ConfigurationBase})

          ActivePropertyExclusionStrategy.new.skip_property?(create_metadata(annotation_configurations: ann_config), ASR::SerializationContext.new).should be_false
        end

        it false do
          ann_config = ADI::AnnotationConfigurations.new({IsActiveProperty => [IsActivePropertyConfiguration.new(false)] of ADI::AnnotationConfigurations::ConfigurationBase})

          ActivePropertyExclusionStrategy.new.skip_property?(create_metadata(annotation_configurations: ann_config), ASR::SerializationContext.new).should be_true
        end
      end
    end
  end
end
