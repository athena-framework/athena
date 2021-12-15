require "./spec_helper"

ACF.configuration_annotation One, id : Int32
ACF.configuration_annotation Two, id : Int32
ACF.configuration_annotation Three, id : Int32 do
  def foo : String
    "foo"
  end
end

describe ACF::AnnotationConfigurations do
  describe ACF::AnnotationConfigurations::ConfigurationBase do
    it "allows defining custom methods on the configuration object" do
      ThreeConfiguration.new(3).foo.should eq "foo"
    end
  end

  describe "#[]" do
    it "returns the last annotation by default" do
      ACF::AnnotationConfigurations.new({
        One => new_annotation_array(OneConfiguration.new(1), OneConfiguration.new(2)),
      } of ACF::AnnotationConfigurations::Classes => Array(ACF::AnnotationConfigurations::ConfigurationBase))[One].id.should eq 2
    end

    it "allows returning a specific index" do
      ACF::AnnotationConfigurations.new({
        One => new_annotation_array(OneConfiguration.new(1), OneConfiguration.new(2)),
      } of ACF::AnnotationConfigurations::Classes => Array(ACF::AnnotationConfigurations::ConfigurationBase))[One, 0].id.should eq 1
    end
  end

  describe "#[]?" do
    it "returns the last annotation by default" do
      annotations = ACF::AnnotationConfigurations.new({
        One => new_annotation_array(OneConfiguration.new(1), OneConfiguration.new(2)),
      } of ACF::AnnotationConfigurations::Classes => Array(ACF::AnnotationConfigurations::ConfigurationBase))[One]?

      ann = annotations.should_not be_nil
      ann.id.should eq 2
    end

    it "allows returning a specific index" do
      annotations = ACF::AnnotationConfigurations.new({
        One => new_annotation_array(OneConfiguration.new(1), OneConfiguration.new(2)),
      } of ACF::AnnotationConfigurations::Classes => Array(ACF::AnnotationConfigurations::ConfigurationBase))[One, 0]?

      ann = annotations.should_not be_nil
      ann.id.should eq 1
    end

    it "returns nil if no annotations of that type exist" do
      ACF::AnnotationConfigurations.new({
        One => new_annotation_array(OneConfiguration.new(1), OneConfiguration.new(2)),
      } of ACF::AnnotationConfigurations::Classes => Array(ACF::AnnotationConfigurations::ConfigurationBase))[Two]?.should be_nil
    end
  end

  describe "#fetch_all" do
    it "returns an array of all annotations of that type" do
      anns = ACF::AnnotationConfigurations.new({
        One => new_annotation_array(OneConfiguration.new(1), OneConfiguration.new(2)),
      } of ACF::AnnotationConfigurations::Classes => Array(ACF::AnnotationConfigurations::ConfigurationBase)).fetch_all One

      anns.size.should eq 2
      anns[0].id.should eq 1
      anns[1].id.should eq 2
    end

    it "returns an empty array if there are no annotations of that type" do
      ACF::AnnotationConfigurations.new({
        One => new_annotation_array(OneConfiguration.new(1), OneConfiguration.new(2)),
      } of ACF::AnnotationConfigurations::Classes => Array(ACF::AnnotationConfigurations::ConfigurationBase)).fetch_all(Two).should be_empty
    end
  end

  describe "#has?" do
    it "returns true if that annotation is present" do
      ACF::AnnotationConfigurations.new({
        One => new_annotation_array(OneConfiguration.new(1), OneConfiguration.new(2)),
      } of ACF::AnnotationConfigurations::Classes => Array(ACF::AnnotationConfigurations::ConfigurationBase)).has?(Two).should be_false
    end
  end
end
