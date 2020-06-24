require "../spec_helper"

private struct TestSerializer
  include ASR::SerializerInterface

  def serialize(data : _, format : ASR::Format | String, context : ASR::SerializationContext = ASR::SerializationContext.new, **named_args) : String
    String.build do |str|
      serialize data, format, str, context, **named_args
    end
  end

  def serialize(data : _, format : ASR::Format | String, io : IO, context : ASR::SerializationContext = ASR::SerializationContext.new, **named_args) : Nil
    io << "SERIALIZED_DATA".to_json
  end

  def deserialize(type : ASR::Model.class, data : String | IO, format : ASR::Format | String, context : ASR::DeserializationContext = ASR::DeserializationContext.new)
  end
end

private record JSONSerializableModel, id : Int32 do
  include JSON::Serializable
end

private record BothSerializableModel, id : Int32 do
  include JSON::Serializable
  include ASR::Serializable
end

describe ART::Listeners::View do
  it "with a Nil return type" do
    route = create_route(Nil) { }
    event = ART::Events::View.new new_request(route: route), nil

    ART::Listeners::View.new(TestSerializer.new).call(event, TracableEventDispatcher.new)

    response = event.response.should_not be_nil
    response.status.should eq HTTP::Status::NO_CONTENT
    response.headers.should eq HTTP::Headers{"content-type" => "application/json"}
    response.content.should be_empty
  end

  describe "with a non Nil return type" do
    describe JSON::Serializable do
      it "should just use .to_json" do
        event = ART::Events::View.new new_request, JSONSerializableModel.new 123

        ART::Listeners::View.new(TestSerializer.new).call(event, TracableEventDispatcher.new)

        response = event.response.should_not be_nil
        response.status.should eq HTTP::Status::OK
        response.headers.should eq HTTP::Headers{"content-type" => "application/json"}
        response.content.should eq %({"id":123})
      end
    end

    describe "JSON::Serializable and ASR::Serializable" do
      it "prioritizes ASR::Serializable" do
        event = ART::Events::View.new new_request, BothSerializableModel.new 456

        ART::Listeners::View.new(TestSerializer.new).call(event, TracableEventDispatcher.new)

        response = event.response.should_not be_nil
        response.status.should eq HTTP::Status::OK
        response.headers.should eq HTTP::Headers{"content-type" => "application/json"}
        response.content.should eq %("SERIALIZED_DATA")
      end
    end

    describe "non JSON::Serializable" do
      it "should use the serializer object" do
        event = ART::Events::View.new new_request, "DATA"

        ART::Listeners::View.new(TestSerializer.new).call(event, TracableEventDispatcher.new)

        response = event.response.should_not be_nil
        response.status.should eq HTTP::Status::OK
        response.headers.should eq HTTP::Headers{"content-type" => "application/json"}
        response.content.should eq %("SERIALIZED_DATA")
      end
    end
  end
end
