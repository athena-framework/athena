require "./routing_spec_helper"

do_with_config do |client|
  describe "param conversion" do
    describe "Int" do
      it "Int8" do
        client.get("/int8/123").body.should eq "123"
        client.post("/int8", body: "123", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "123"
      end

      it "Int16" do
        client.get("/int16/456").body.should eq "456"
        client.post("/int16/", body: "456", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "456"
      end

      it "Int32" do
        client.get("/int32/111111").body.should eq "111111"
        client.post("/int32/", body: "111111", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "111111"
      end

      it "Int64" do
        client.get("/int64/9999999999999999").body.should eq "9999999999999999"
        client.post("/int64/", body: "9999999999999999", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "9999999999999999"
      end

      pending "Int128" do
        client.get("/int128/9999999999999999999999").body.should eq "9999999999999999999999"
        client.post("/int128/", body: "9999999999999999999999", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "9999999999999999999999"
      end

      it "invalid" do
        response = client.get("/int32/1.00")
        response.body.should eq %({"code": 400, "message": "Invalid Int32: 1.00"})
        response.status.should eq HTTP::Status::BAD_REQUEST
      end
    end

    describe "UInt" do
      it "UInt8" do
        client.get("/uint8/123").body.should eq "123"
        client.post("/uint8", body: "123", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "123"
      end

      it "UInt16" do
        client.get("/uint16/456").body.should eq "456"
        client.post("/uint16", body: "456", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "456"
      end

      it "UInt32" do
        client.get("/uint32/111111").body.should eq "111111"
        client.post("/uint32", body: "111111", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "111111"
      end

      it "UInt64" do
        client.get("/uint64/9999999999999999").body.should eq "9999999999999999"
        client.post("/uint64/", body: "9999999999999999", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "9999999999999999"
      end

      pending "UInt128" do
        client.get("/uint128/9999999999999999999999").body.should eq "9999999999999999999999"
        client.post("/uint128/", body: "9999999999999999999999", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "9999999999999999999999"
      end

      it "invalid" do
        response = client.get("/uint8/256")
        response.body.should eq %({"code": 400, "message": "Invalid UInt8: 256"})
        response.status.should eq HTTP::Status::BAD_REQUEST
      end
    end

    describe "Float" do
      it "Float32" do
        client.get("/float32/-2342.223").body.should eq "-2342.223"
        client.post("/float32/", body: "-2342.223", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "-2342.223"
      end

      it "Float64" do
        client.get("/float64/2342.234234234223").body.should eq "2342.234234234223"
        client.post("/float64", body: "2342.234234234223", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "2342.234234234223"
      end

      it "invalid" do
        response = client.get("/float64/foo")
        response.body.should eq %({"code": 400, "message": "Invalid Float64: foo"})
        response.status.should eq HTTP::Status::BAD_REQUEST
      end
    end

    describe "Bool" do
      it "Bool" do
        client.get("/bool/true").body.should eq "true"
        client.post("/bool", body: "true", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "true"
      end
    end

    describe "String" do
      it "String" do
        client.get("/string/sdfsd").body.should eq "\"sdfsd\""
        client.post("/string", body: "sdfsd", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "\"sdfsd\""
      end
    end

    describe "Negative values" do
      it "should return properly" do
        client.get("/negative/123").body.should eq "-123"
        client.post("/negative", body: "123", headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq "-123"
      end
    end
  end
end
