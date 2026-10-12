require "../../spec_helper"

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, code, line: line, preamble: <<-'CR', postamble: "ATH.run"
    require "../../../src/athena"
    require "athena-serializer"
  CR
end

private def assert_compiles(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compiles code, line: line, preamble: <<-'CR', postamble: "ATH.run"
    require "../../../src/athena"
    require "athena-serializer"
  CR
end

describe "Serializer bundle not registered", tags: "compiled" do
  it "serializes views and deserializes request bodies natively without the Serializer component" do
    ASPEC::Methods.assert_executes <<-'CR'
      require "../../../src/athena"
      require "../../../src/spec"

      record JSONEntity, id : Int32 do
        include JSON::Serializable
      end

      record FormEntity, id : Int32 do
        include URI::Params::Serializable
      end

      class NativeController < ATH::Controller
        @[ARTA::Post("/json")]
        def json(@[ATHA::MapRequestBody] entity : JSONEntity) : JSONEntity
          entity
        end

        @[ARTA::Post("/form")]
        def form(@[ATHA::MapRequestBody] entity : FormEntity) : Int32
          entity.id
        end

        @[ARTA::Get("/collection")]
        def collection : NamedTuple(entities: Array(JSONEntity))
          {entities: [JSONEntity.new(1), JSONEntity.new(2)]}
        end
      end

      struct NativeSerializationTest < ATH::Spec::APITestCase
        def test_json_request_body : Nil
          self.post("/json", %({"id":10}), headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq %({"id":10})
        end

        def test_malformed_json_request_body : Nil
          self.post "/json", %({"id":), headers: HTTP::Headers{"content-type" => "application/json"}
          self.assert_response_has_status :bad_request
        end

        def test_form_request_body : Nil
          self.post("/form", "id=10", headers: HTTP::Headers{"content-type" => "application/x-www-form-urlencoded"}).body.should eq "10"
        end

        def test_view : Nil
          self.get("/collection").body.should eq %({"entities":[{"id":1},{"id":2}]})
        end
      end

      ASPEC.run_all

      raise "Expected the Serializer component to not be required" if {{ @top_level.has_constant? "ASR" }}
    CR
  end

  describe "with the Serializer component" do
    it "serializes JSON::Serializable types natively" do
      assert_compiles <<-'CR'
        record JSONEntity, id : Int32 do
          include JSON::Serializable
        end

        class CompileController < ATH::Controller
          @[ARTA::Post("/")]
          def action(@[ATHA::MapRequestBody] entity : JSONEntity) : NamedTuple(entities: Array(JSONEntity), total: Int32?)
            {entities: [entity], total: 1}
          end
        end
      CR
    end

    it "errors if an action returns ASR::Serializable data" do
      assert_compile_time_error %(The return type of route action 'CompileController#action' contains 'ASREntity', which includes 'ASR::Serializable', but the Serializer bundle is not registered. Add `require "athena-serializer/bundle"` to serialize it.), <<-'CR'
        class ASREntity
          include ASR::Serializable

          getter id : Int32 = 1

          def initialize; end
        end

        class CompileController < ATH::Controller
          @[ARTA::Get("/")]
          def action : ATH::View(Hash(String, Array(ASREntity)))
            self.view({"entities" => [ASREntity.new]})
          end
        end
      CR
    end

    it "errors if a request body is ASR::Serializable" do
      assert_compile_time_error " The annotation '@[ATHA::MapRequestBody]' cannot be applied to 'CompileController#action:entity : ASREntity' since the 'Athena::Framework::Controller::ValueResolvers::RequestBody' resolver only supports parameters of type 'JSON::Serializable | URI::Params::Serializable | (Athena::HTTP::UploadedFile | Nil) | Array(Athena::HTTP::UploadedFile)'.", <<-'CR'
        class ASREntity
          include ASR::Serializable

          getter id : Int32 = 1
        end

        class CompileController < ATH::Controller
          @[ARTA::Post("/")]
          def action(@[ATHA::MapRequestBody] entity : ASREntity) : Nil
          end
        end
      CR
    end
  end
end
