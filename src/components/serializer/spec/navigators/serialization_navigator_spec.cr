require "../spec_helper"

describe ASR::Navigators::SerializationNavigator do
  describe "#accept" do
    describe ASRA::PreSerialize do
      it "should run pre serialize methods" do
        obj = PreSerialize.new
        obj.name.should be_nil
        obj.age.should be_nil

        visitor = create_serialization_visitor do |properties|
          properties.size.should eq 2
          p = properties[0]

          p.name.should eq "name"
          p.external_name.should eq "name"
          p.value.should eq "NAME"
          p.skip_when_empty?.should be_false
          p.groups.should eq Set{"default"}
          p.type.should eq String?
          p.class.should eq PreSerialize

          p = properties[1]

          p.name.should eq "age"
          p.external_name.should eq "age"
          p.value.should eq 123
          p.skip_when_empty?.should be_false
          p.groups.should eq Set{"default"}
          p.type.should eq Int32?
          p.class.should eq PreSerialize
        end

        ASR::Navigators::SerializationNavigator.new(visitor, ASR::SerializationContext.new).accept obj

        obj.name.should eq "NAME"
        obj.age.should eq 123
      end
    end

    describe ASRA::PostSerialize do
      it "should run pre serialize methods" do
        obj = PostSerialize.new
        obj.name.should be_nil
        obj.age.should be_nil

        visitor = create_serialization_visitor do |properties|
          properties.size.should eq 2
          p = properties[0]

          p.name.should eq "name"
          p.external_name.should eq "name"
          p.value.should eq "NAME"
          p.skip_when_empty?.should be_false
          p.groups.should eq Set{"default"}
          p.type.should eq String?
          p.class.should eq PostSerialize

          p = properties[1]

          p.name.should eq "age"
          p.external_name.should eq "age"
          p.value.should eq 123
          p.skip_when_empty?.should be_false
          p.groups.should eq Set{"default"}
          p.type.should eq Int32?
          p.class.should eq PostSerialize
        end

        ASR::Navigators::SerializationNavigator.new(visitor, ASR::SerializationContext.new).accept obj

        obj.name.should be_nil
        obj.age.should be_nil
      end
    end

    describe ASRA::SkipWhenEmpty do
      it "should not serialize empty properties" do
        obj = SkipWhenEmpty.new
        obj.value = ""

        visitor = create_serialization_visitor do |properties|
          properties.should be_empty
        end

        ASR::Navigators::SerializationNavigator.new(visitor, ASR::SerializationContext.new).accept obj
      end

      it "should serialize non-empty properties" do
        obj = SkipWhenEmpty.new

        visitor = create_serialization_visitor do |properties|
          properties.size.should eq 1
          p = properties[0]

          p.name.should eq "value"
          p.external_name.should eq "value"
          p.value.should eq "value"
          p.skip_when_empty?.should be_true
          p.groups.should eq Set{"default"}
          p.type.should eq String
          p.class.should eq SkipWhenEmpty
        end

        ASR::Navigators::SerializationNavigator.new(visitor, ASR::SerializationContext.new).accept obj
      end
    end

    describe :emit_nil do
      describe "with the default value" do
        it "should not include nil values" do
          obj = EmitNil.new

          visitor = create_serialization_visitor do |properties|
            properties.size.should eq 1
            p = properties[0]

            p.name.should eq "age"
            p.external_name.should eq "age"
            p.value.should eq 1
            p.skip_when_empty?.should be_false
            p.groups.should eq Set{"default"}
            p.type.should eq Int32
            p.class.should eq EmitNil
          end

          ASR::Navigators::SerializationNavigator.new(visitor, ASR::SerializationContext.new).accept obj
        end
      end

      describe "when enabled" do
        it "should include nil values" do
          obj = EmitNil.new
          ctx = ASR::SerializationContext.new
          ctx.emit_nil = true

          visitor = create_serialization_visitor do |properties|
            properties.size.should eq 2
            p = properties[0]

            p.name.should eq "name"
            p.external_name.should eq "name"
            p.value.should be_nil
            p.skip_when_empty?.should be_false
            p.groups.should eq Set{"default"}
            p.type.should eq String?
            p.class.should eq EmitNil

            p = properties[1]

            p.name.should eq "age"
            p.external_name.should eq "age"
            p.value.should eq 1
            p.skip_when_empty?.should be_false
            p.groups.should eq Set{"default"}
            p.type.should eq Int32
            p.class.should eq EmitNil
          end

          ASR::Navigators::SerializationNavigator.new(visitor, ctx).accept obj
        end
      end
    end

    describe ASRA::Groups do
      describe "without any groups in the context" do
        it "should include all properties" do
          obj = Group.new

          visitor = create_serialization_visitor do |properties|
            properties.size.should eq 4

            p = properties[0]

            p.name.should eq "id"
            p.external_name.should eq "id"
            p.value.should eq 1
            p.skip_when_empty?.should be_false
            p.groups.should eq Set{"list", "details"}
            p.type.should eq Int64
            p.class.should eq Group

            p = properties[1]

            p.name.should eq "comment_summaries"
            p.external_name.should eq "comment_summaries"
            p.value.should eq ["Sentence 1.", "Sentence 2."]
            p.skip_when_empty?.should be_false
            p.groups.should eq Set{"list"}
            p.type.should eq Array(String)
            p.class.should eq Group

            p = properties[2]

            p.name.should eq "comments"
            p.external_name.should eq "comments"
            p.value.should eq ["Sentence 1.  Another sentence.", "Sentence 2.  Some other stuff."]
            p.skip_when_empty?.should be_false
            p.groups.should eq Set{"details"}
            p.type.should eq Array(String)
            p.class.should eq Group

            p = properties[3]

            p.name.should eq "created_at"
            p.external_name.should eq "created_at"
            p.value.should eq Time.utc(2019, 1, 1)
            p.skip_when_empty?.should be_false
            p.groups.should eq Set{"default"}
            p.type.should eq Time
            p.class.should eq Group
          end

          ASR::Navigators::SerializationNavigator.new(visitor, ASR::SerializationContext.new).accept obj
        end
      end

      describe "with a group specified" do
        it "should exclude properties not in the given groups" do
          obj = Group.new
          ctx = ASR::SerializationContext.new.groups = ["list"]

          # Manually call init here to set the exclusion strategies,
          # normally this gets handled in the serializer instance
          ctx.init

          visitor = create_serialization_visitor do |properties|
            properties.size.should eq 2

            p = properties[0]

            p.name.should eq "id"
            p.external_name.should eq "id"
            p.value.should eq 1
            p.skip_when_empty?.should be_false
            p.groups.should eq Set{"list", "details"}
            p.type.should eq Int64
            p.class.should eq Group

            p = properties[1]

            p.name.should eq "comment_summaries"
            p.external_name.should eq "comment_summaries"
            p.value.should eq ["Sentence 1.", "Sentence 2."]
            p.skip_when_empty?.should be_false
            p.groups.should eq Set{"list"}
            p.type.should eq Array(String)
            p.class.should eq Group
          end

          ASR::Navigators::SerializationNavigator.new(visitor, ctx).accept obj
        end
      end

      describe "that is in the default group" do
        it "should include properties without groups explicitly defined" do
          obj = Group.new
          ctx = ASR::SerializationContext.new.groups = ["list", "default"]

          # Manually call init here to set the exclusion strategies,
          # normally this gets handled in the serializer instance
          ctx.init

          visitor = create_serialization_visitor do |properties|
            properties.size.should eq 3

            p = properties[0]

            p.name.should eq "id"
            p.external_name.should eq "id"
            p.value.should eq 1
            p.skip_when_empty?.should be_false
            p.groups.should eq Set{"list", "details"}
            p.type.should eq Int64
            p.class.should eq Group

            p = properties[1]

            p.name.should eq "comment_summaries"
            p.external_name.should eq "comment_summaries"
            p.value.should eq ["Sentence 1.", "Sentence 2."]
            p.skip_when_empty?.should be_false
            p.groups.should eq Set{"list"}
            p.type.should eq Array(String)
            p.class.should eq Group

            p = properties[2]

            p.name.should eq "created_at"
            p.external_name.should eq "created_at"
            p.value.should eq Time.utc(2019, 1, 1)
            p.skip_when_empty?.should be_false
            p.groups.should eq Set{"default"}
            p.type.should eq Time
            p.class.should eq Group
          end

          ASR::Navigators::SerializationNavigator.new(visitor, ctx).accept obj
        end
      end
    end

    describe "primitive type" do
      it "should write the value" do
        io = IO::Memory.new
        ASR::Navigators::SerializationNavigator.new(TestSerializationVisitor.new(io, NamedTuple.new), ASR::SerializationContext.new).accept "FOO"
        io.rewind.gets_to_end.should eq "FOO"
      end
    end
  end
end
