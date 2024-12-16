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

private record MockURISerializableEntity, id : Int32, name : String do
  include URI::Params::Serializable
end

private record MockJSONAndURISerializableEntity, id : Int32, name : String do
  include JSON::Serializable
  include URI::Params::Serializable
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
    expect_raises ATH::Exception::BadRequest, "Request does not have a body." do
      @target.resolve new_request, self.get_config MockJSONSerializableEntity
    end
  end

  def test_raises_on_empty_body : Nil
    expect_raises ATH::Exception::BadRequest, "Request does not have a body." do
      @target.resolve new_request(body: ""), self.get_config(MockJSONSerializableEntity)
    end
  end

  def test_raises_on_invalid_json : Nil
    expect_raises ATH::Exception::BadRequest, "Malformed JSON payload." do
      @target.resolve new_request(body: %(<blah>)), self.get_config(MockJSONSerializableEntity)
    end
  end

  def test_raises_on_invalid_nested_json : Nil
    expect_raises ATH::Exception::BadRequest, "Malformed JSON payload." do
      @target.resolve new_request(body: %({"id": "foo"})), self.get_config(MockJSONSerializableEntity)
    end
  end

  def test_raises_on_missing_json_data : Nil
    expect_raises ATH::Exception::UnprocessableEntity, "Missing JSON attribute: name" do
      @target.resolve new_request(body: %({"id":10})), self.get_config(MockJSONSerializableEntity)
    end
  end

  def test_raises_on_missing_www_form_data : Nil
    expect_raises ATH::Exception::UnprocessableEntity, "Missing required property: 'name'." do
      @target.resolve new_request(body: "id=10", format: "form"), self.get_config(MockURISerializableEntity)
    end
  end

  def test_raises_on_missing_query_string_data : Nil
    expect_raises ATH::Exception::UnprocessableEntity, "Missing required property: 'name'." do
      @target.resolve new_request(query: "id=10"), self.get_config(MockURISerializableEntity, ATHA::MapQueryString, ATHA::MapQueryStringConfiguration.new)
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

    expect_raises AVD::Exception::ValidationFailed, "Validation failed" do
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

  def test_it_supports_uri_params_serializable : Nil
    serializer = DeserializableMockSerializer(MockURISerializableEntity).new
    serializer.deserialized_response = MockURISerializableEntity.new 10, "Fred"

    request = new_request body: "id=10&name=Fred", format: "form"

    object = ATHR::RequestBody.new(serializer, @validator).resolve request, self.get_config(MockURISerializableEntity)
    object = object.should_not be_nil

    object.id.should eq 10
    object.name.should eq "Fred"
  end

  def test_it_supports_specifying_accepted_formats : Nil
    expect_raises ATH::Exception::UnsupportedMediaType, %(Unsupported format, expects one of: 'json, xml', but got 'form'.) do
      @target.resolve(
        new_request(body: "id=10&name=Fred", format: "form"),
        self.get_config(MockURISerializableEntity, configuration: ATHA::MapRequestBodyConfiguration.new(["json", "xml"]))
      )
    end
  end

  def test_it_supports_query_string_serializable : Nil
    serializer = DeserializableMockSerializer(MockURISerializableEntity).new
    serializer.deserialized_response = MockURISerializableEntity.new 10, "Fred"

    request = new_request query: "id=10&name=Fred"

    object = ATHR::RequestBody.new(serializer, @validator).resolve request, self.get_config(MockURISerializableEntity, ATHA::MapQueryString, ATHA::MapQueryStringConfiguration.new)
    object = object.should_not be_nil

    object.id.should eq 10
    object.name.should eq "Fred"
  end

  def test_it_supports_query_string_serializable_no_query_string : Nil
    serializer = DeserializableMockSerializer(MockURISerializableEntity).new
    serializer.deserialized_response = MockURISerializableEntity.new 10, "Fred"

    ATHR::RequestBody
      .new(serializer, @validator)
      .resolve(new_request, self.get_config(MockURISerializableEntity, ATHA::MapQueryString, ATHA::MapQueryStringConfiguration.new))
      .should be_nil
  end

  def test_it_supports_multiple_serializable : Nil
    serializer = DeserializableMockSerializer(MockJSONAndURISerializableEntity).new
    serializer.deserialized_response = MockJSONAndURISerializableEntity.new 10, "Fred"

    form_request = new_request body: "id=10&name=Fred", format: "form"
    json_request = new_request body: %({"id":10,"name":"Fred"})

    resolver = ATHR::RequestBody.new serializer, @validator
    form_object = resolver.resolve form_request, self.get_config(MockJSONAndURISerializableEntity)
    form_object = form_object.should_not be_nil

    json_object = resolver.resolve json_request, self.get_config(MockJSONAndURISerializableEntity)
    json_object = json_object.should_not be_nil

    form_object.id.should eq 10
    form_object.name.should eq "Fred"

    json_object.id.should eq 10
    json_object.name.should eq "Fred"
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

  private def get_config(type : T.class, ann = ATHA::MapRequestBody, configuration = ATHA::MapRequestBodyConfiguration.new) forall T
    ATH::Controller::ParameterMetadata(T).new(
      "foo",
      annotation_configurations: ADI::AnnotationConfigurations.new({
        ann => [
          configuration,
        ] of ADI::AnnotationConfigurations::ConfigurationBase,
      } of ADI::AnnotationConfigurations::Classes => Array(ADI::AnnotationConfigurations::ConfigurationBase))
    )
  end
end
