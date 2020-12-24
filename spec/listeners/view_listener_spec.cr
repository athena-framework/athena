require "../spec_helper"

# private struct TestSerializer
#   include ASR::SerializerInterface

#   def initialize(@context_assertion : Proc(ASR::SerializationContext, Nil)? = nil); end

#   def serialize(data : _, format : ASR::Format | String, context : ASR::SerializationContext = ASR::SerializationContext.new, **named_args) : String
#     String.build do |str|
#       serialize data, format, str, context, **named_args
#     end
#   end

#   def serialize(data : _, format : ASR::Format | String, io : IO, context : ASR::SerializationContext = ASR::SerializationContext.new, **named_args) : Nil
#     "SERIALIZED_DATA".to_json io

#     @context_assertion.try &.call context
#   end

#   def deserialize(type : ASR::Model.class, data : String | IO, format : ASR::Format | String, context : ASR::DeserializationContext = ASR::DeserializationContext.new)
#   end
# end

# private record JSONSerializableModel, id : Int32 do
#   include JSON::Serializable
# end

# private record BothSerializableModel, id : Int32 do
#   include JSON::Serializable
#   include ASR::Serializable
# end

describe ART::Listeners::View do
end

# describe ART::Listeners::View do
#   describe "with a Nil return type" do
#     it "with the default status" do
#       route = create_action(Nil) { }
#       event = ART::Events::View.new new_request(action: route), nil

#       ART::Listeners::View.new(TestSerializer.new).call(event, AED::Spec::TracableEventDispatcher.new)

#       response = event.response.should_not be_nil
#       response.status.should eq HTTP::Status::NO_CONTENT
#       response.headers.should eq HTTP::Headers{"content-type" => "application/json; charset=UTF-8"}
#       response.content.should be_empty
#     end

#     it "with a customized status" do
#       route = create_action(Nil, view_context: ART::Action::ViewContext.new(status: :im_a_teapot)) { }
#       event = ART::Events::View.new new_request(action: route), nil

#       ART::Listeners::View.new(TestSerializer.new).call(event, AED::Spec::TracableEventDispatcher.new)

#       response = event.response.should_not be_nil
#       response.status.should eq HTTP::Status::IM_A_TEAPOT
#       response.headers.should eq HTTP::Headers{"content-type" => "application/json; charset=UTF-8"}
#       response.content.should be_empty
#     end

#     it "with a 200 status" do
#       route = create_action(Nil, view_context: ART::Action::ViewContext.new(status: :ok)) { }
#       event = ART::Events::View.new new_request(action: route), nil

#       ART::Listeners::View.new(TestSerializer.new).call(event, AED::Spec::TracableEventDispatcher.new)

#       response = event.response.should_not be_nil
#       response.status.should eq HTTP::Status::OK
#       response.headers.should eq HTTP::Headers{"content-type" => "application/json; charset=UTF-8"}
#       response.content.should be_empty
#     end
#   end

#   describe "with a non Nil return type" do
#     describe JSON::Serializable do
#       it "should just use .to_json" do
#         event = ART::Events::View.new new_request, JSONSerializableModel.new 123

#         ART::Listeners::View.new(TestSerializer.new).call(event, AED::Spec::TracableEventDispatcher.new)

#         response = event.response.should_not be_nil
#         response.status.should eq HTTP::Status::OK
#         response.headers.should eq HTTP::Headers{"content-type" => "application/json; charset=UTF-8"}
#         response.content.should eq %({"id":123})
#       end
#     end

#     describe ASR::Serializable do
#       it "should use the serializer object" do
#         event = ART::Events::View.new new_request, "DATA"

#         ART::Listeners::View.new(TestSerializer.new).call(event, AED::Spec::TracableEventDispatcher.new)

#         response = event.response.should_not be_nil
#         response.status.should eq HTTP::Status::OK
#         response.headers.should eq HTTP::Headers{"content-type" => "application/json; charset=UTF-8"}
#         response.content.should eq %("SERIALIZED_DATA")
#       end

#       it "allows setting the serializer context" do
#         view_context = ART::Action::ViewContext.new emit_nil: true, serialization_groups: ["some_group"]

#         # Simulate some listener setting this.
#         # In practice it'll be retrieved off the action object.
#         view_context.version = "1.2.3"

#         event = ART::Events::View.new new_request(action: new_action(view_context: view_context)), "foo"

# serializer = TestSerializer.new ->(context : ASR::SerializationContext) do
#   context.emit_nil?.should be_true
#   context.groups.should eq Set{"some_group"}
#   context.version.to_s.should eq "1.2.3"
# end

#         serializer = TestSerializer.new ->(context : ASR::SerializationContext) do
#           context.emit_nil?.should be_true
#           context.groups.should eq ["some_group"]
#           context.version.to_s.should eq "1.2.3"
#         end

#         ART::Listeners::View.new(serializer).call(event, AED::Spec::TracableEventDispatcher.new)
#       end
#     end

#     describe "JSON::Serializable and ASR::Serializable" do
#       it "prioritizes ASR::Serializable" do
#         event = ART::Events::View.new new_request, BothSerializableModel.new 456

#         ART::Listeners::View.new(TestSerializer.new).call(event, AED::Spec::TracableEventDispatcher.new)

#         response = event.response.should_not be_nil
#         response.status.should eq HTTP::Status::OK
#         response.headers.should eq HTTP::Headers{"content-type" => "application/json; charset=UTF-8"}
#         response.content.should eq %("SERIALIZED_DATA")
#       end
#     end

#     it "allows defining a custom response status" do
#       event = ART::Events::View.new new_request(action: new_action(view_context: ART::Action::ViewContext.new(status: HTTP::Status::IM_A_TEAPOT))), "foo"

#       ART::Listeners::View.new(TestSerializer.new).call(event, AED::Spec::TracableEventDispatcher.new)

#       response = event.response.should_not be_nil
#       response.status.should eq HTTP::Status::IM_A_TEAPOT
#       response.headers.should eq HTTP::Headers{"content-type" => "application/json; charset=UTF-8"}
#       response.content.should eq %("SERIALIZED_DATA")
#     end
#   end
# end
