require "../../spec_helper"

private record MockJSONSerializableEntity, id : Int32, name : String do
  include JSON::Serializable
end

private record MockASRSerializableEntity, id : Int32, name : String do
  include ASR::Serializable
end

private record MockValidatableASRSerializableEntity, id : Int32, name : String do
  include ASR::Serializable
  include AVD::Validatable
end

struct RequestBodyResolverTest < ASPEC::TestCase
  @target : ATHR::RequestBody

  @serializer : ASR::SerializerInterface
  @validator : AVD::Validator::ValidatorInterface

  def initialize
    @validator = AVD::Spec::MockValidator.new
    @serializer = DeserializableMockSerializer(Nil).new

    @target = ATHR::RequestBody.new @serializer, @validator
  end

  def test_no_annotation : Nil
    ATHR::RequestBody.new(@serializer, @validator).resolve(new_request, new_parameter).should be_nil
  end

  def test_raises_on_no_body : Nil
    expect_raises ATH::Exceptions::BadRequest, "Request does not have a body." do
      @target.resolve new_request, self.get_config MockJSONSerializableEntity
    end
  end

  def test_raises_on_empty_body : Nil
    expect_raises ATH::Exceptions::BadRequest, "Request does not have a body." do
      @target.resolve new_request(body: ""), self.get_config(MockJSONSerializableEntity)
    end
  end

  def test_raises_on_invalid_json : Nil
    expect_raises ATH::Exceptions::BadRequest, "Malformed JSON payload." do
      @target.resolve new_request(body: "<abc123>"), self.get_config(MockJSONSerializableEntity)
    end
  end

  def test_it_raises_on_constraint_violations : Nil
    serializer = DeserializableMockSerializer(MockValidatableASRSerializableEntity).new
    serializer.deserialized_response = MockValidatableASRSerializableEntity.new 10, ""

    validator = AVD::Spec::MockValidator.new(
      AVD::Violation::ConstraintViolationList.new([
        AVD::Violation::ConstraintViolation.new("error", "error", Hash(String, String).new, "", ".name", AVD::ValueContainer.new("")),
      ])
    )

    expect_raises AVD::Exceptions::ValidationFailed, "Validation failed" do
      ATHR::RequestBody.new(serializer, validator).resolve new_request(body: %({"id":10,"name":""})), self.get_config(MockValidatableASRSerializableEntity)
    end
  end

  def test_it_supports_json_serializable : Nil
    request = new_request body: %({"id":10,"name":"Fred"})

    object = @target.resolve request, self.get_config(MockJSONSerializableEntity)
    object = object.should_not be_nil

    object.id.should eq 10
    object.name.should eq "Fred"
  end

  def test_it_supports_asr_serializable : Nil
    serializer = DeserializableMockSerializer(MockASRSerializableEntity).new
    serializer.deserialized_response = MockASRSerializableEntity.new 10, "Fred"

    request = new_request body: %({"id":10,"name":"Fred"})

    object = ATHR::RequestBody.new(serializer, @validator).resolve request, self.get_config(MockASRSerializableEntity)
    object = object.should_not be_nil

    object.id.should eq 10
    object.name.should eq "Fred"
  end

  def test_it_supports_avd_validatable : Nil
    serializer = DeserializableMockSerializer(MockValidatableASRSerializableEntity).new
    serializer.deserialized_response = MockValidatableASRSerializableEntity.new 10, "Fred"

    request = new_request body: %({"id":10,"name":"Fred"})

    object = ATHR::RequestBody.new(serializer, @validator).resolve request, self.get_config(MockValidatableASRSerializableEntity)
    object = object.should_not be_nil

    object.id.should eq 10
    object.name.should eq "Fred"
  end

  private def get_config(type : T.class) forall T
    ATH::Controller::ParameterMetadata(T).new(
      "foo",
      annotation_configurations: ACF::AnnotationConfigurations.new({
        ATHR::RequestBody::Extract => [
          ATHR::RequestBody::ExtractConfiguration.new,
        ] of ACF::AnnotationConfigurations::ConfigurationBase,
      } of ACF::AnnotationConfigurations::Classes => Array(ACF::AnnotationConfigurations::ConfigurationBase))
    )
  end
end
