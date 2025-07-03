require "../spec_helper"

describe ASR::Navigators::DeserializationNavigator do
  describe "#accept" do
    describe ASRA::PostDeserialize do
      it "should run post deserialize methods" do
        data = JSON.parse %({"name": "First Last"})

        visitor = create_deserialization_visitor do |properties|
          properties.size.should eq 1
          p = properties[0]

          p.name.should eq "name"
          p.external_name.should eq "name"
          p.skip_when_empty?.should be_false
          p.groups.should eq ["default"] of String
          p.type.should eq String?
          p.class.should eq PostDeserialize

          obj = PostDeserialize.new

          obj.first_name.should be_nil
          obj.last_name.should be_nil

          obj
        end

        obj = ASR::Navigators::DeserializationNavigator.new(visitor, ASR::DeserializationContext.new, ASR::InstantiateObjectConstructor.new).accept(PostDeserialize, data).as(PostDeserialize)

        obj.first_name.should eq "First"
        obj.last_name.should eq "Last"
      end
    end
  end
end
