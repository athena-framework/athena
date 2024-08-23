require "../../spec_helper"

private def parameter(
  klass : T.class = String,
  *,
  name : String? = nil,
  validation_failed_status : HTTP::Status = :not_found,
  default : T? = nil
) forall T
  ATH::Controller::ParameterMetadata(T).new(
    "foo",
    default_value: default,
    has_default: !default.nil?,
    annotation_configurations: ADI::AnnotationConfigurations.new({
      ATHA::MapQueryParameter => [
        ATHA::MapQueryParameterConfiguration.new(name, validation_failed_status),
      ] of ADI::AnnotationConfigurations::ConfigurationBase,
    } of ADI::AnnotationConfigurations::Classes => Array(ADI::AnnotationConfigurations::ConfigurationBase))
  )
end

describe ATHR::QueryParameter do
  describe "#resolve" do
    it "does not have the annotation" do
      parameter = ATH::Controller::ParameterMetadata(String).new "foo"
      ATHR::QueryParameter.new.resolve(new_request, parameter).should be_nil
    end

    it "valid scalar parameter" do
      ATHR::QueryParameter.new.resolve(new_request(query: "foo=bar"), parameter).should eq "bar"
    end

    it "custom param name" do
      ATHR::QueryParameter.new.resolve(new_request(query: "blah=bar"), parameter name: "blah").should eq "bar"
    end

    it "valid array parameter" do
      ATHR::QueryParameter.new.resolve(new_request(query: "foo=1&foo=2"), parameter(Array(Int32))).should eq [1, 2]
    end

    it "missing nilable" do
      ATHR::QueryParameter.new.resolve(new_request, parameter(Float64?)).should be_nil
    end

    it "non-nilable with default" do
      ATHR::QueryParameter.new.resolve(new_request, parameter(Bool, default: false)).should be_nil
    end

    it "missing non-nilable no default" do
      expect_raises ATH::Exception::NotFound, "Missing query parameter: 'foo'." do
        ATHR::QueryParameter.new.resolve new_request, parameter
      end
    end

    it "missing non-nilable no default custom status" do
      expect_raises ATH::Exception::UnprocessableEntity, "Missing query parameter: 'foo'." do
        ATHR::QueryParameter.new.resolve new_request, parameter(validation_failed_status: :unprocessable_entity)
      end
    end

    it "invalid" do
      expect_raises ATH::Exception::NotFound, "Invalid query parameter: 'foo'." do
        ATHR::QueryParameter.new.resolve new_request(query: "foo=bar"), parameter(Int32)
      end
    end

    it "missing non-nilable no default custom status" do
      expect_raises ATH::Exception::UnprocessableEntity, "Invalid query parameter: 'foo'." do
        ATHR::QueryParameter.new.resolve new_request(query: "foo=bar"), parameter(Int32, validation_failed_status: :unprocessable_entity)
      end
    end
  end
end
