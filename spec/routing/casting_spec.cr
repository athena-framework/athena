require "./routing_spec_helper"

do_with_config do
  describe "param conversion" do
    context "Int" do
      it "Int8" do
        CLIENT.get("/int8/123").body.should eq "123"
        CLIENT.post("/int8", body: "123", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "123"
      end

      it "Int16" do
        CLIENT.get("/int16/456").body.should eq "456"
        CLIENT.post("/int16/", body: "456", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "456"
      end

      it "Int32" do
        CLIENT.get("/int32/111111").body.should eq "111111"
        CLIENT.post("/int32/", body: "111111", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "111111"
      end

      it "Int64" do
        CLIENT.get("/int64/9999999999999999").body.should eq "9999999999999999"
        CLIENT.post("/int64/", body: "9999999999999999", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "9999999999999999"
      end

      pending "Int128" do
        CLIENT.get("/int128/9999999999999999999999").body.should eq "9999999999999999999999"
        CLIENT.post("/int128/", body: "9999999999999999999999", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "9999999999999999999999"
      end

      it "invalid" do
        response = CLIENT.get("/int32/1.00")
        response.body.should eq %({"code": 400, "message": "Invalid Int32: 1.00"})
        response.status_code.should eq 400
      end
    end

    context "UInt" do
      it "UInt8" do
        CLIENT.get("/uint8/123").body.should eq "123"
        CLIENT.post("/uint8", body: "123", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "123"
      end

      it "UInt16" do
        CLIENT.get("/uint16/456").body.should eq "456"
        CLIENT.post("/uint16", body: "456", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "456"
      end

      it "UInt32" do
        CLIENT.get("/uint32/111111").body.should eq "111111"
        CLIENT.post("/uint32", body: "111111", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "111111"
      end

      it "UInt64" do
        CLIENT.get("/uint64/9999999999999999").body.should eq "9999999999999999"
        CLIENT.post("/uint64/", body: "9999999999999999", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "9999999999999999"
      end

      pending "UInt128" do
        CLIENT.get("/uint128/9999999999999999999999").body.should eq "9999999999999999999999"
        CLIENT.post("/uint128/", body: "9999999999999999999999", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "9999999999999999999999"
      end

      it "invalid" do
        response = CLIENT.get("/uint8/256")
        response.body.should eq %({"code": 400, "message": "Invalid UInt8: 256"})
        response.status_code.should eq 400
      end
    end

    context "Float" do
      it "Float32" do
        CLIENT.get("/float32/-2342.223").body.should eq "-2342.223"
        CLIENT.post("/float32/", body: "-2342.223", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "-2342.223"
      end

      it "Float64" do
        CLIENT.get("/float64/2342.234234234223").body.should eq "2342.234234234223"
        CLIENT.post("/float64", body: "2342.234234234223", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "2342.234234234223"
      end

      it "invalid" do
        response = CLIENT.get("/float64/foo")
        response.body.should eq %({"code": 400, "message": "Invalid Float64: foo"})
        response.status_code.should eq 400
      end
    end

    context "Bool" do
      it "Bool" do
        CLIENT.get("/bool/true").body.should eq "true"
        CLIENT.post("/bool", body: "true", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "true"
      end
    end

    context "String" do
      it "String" do
        CLIENT.get("/string/sdfsd").body.should eq "\"sdfsd\""
        CLIENT.post("/string", body: "sdfsd", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "\"sdfsd\""
      end
    end

    context "Struct" do
      it "Struct" do
        CLIENT.get("/struct/123").body.should eq "-123"
        CLIENT.post("/struct", body: "123", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "-123"
      end
    end
  end
end
