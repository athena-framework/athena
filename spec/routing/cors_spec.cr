require "./routing_spec_helper"

do_with_config(CORS_CONFIG) do |client|
  describe Athena::Routing::Handlers::CorsHandler do
    describe "defaults" do
      describe "GET" do
        it "should add the allow origin header" do
          response = client.get("/defaults")
          response.headers["Access-Control-Allow-Origin"]?.should eq "DEFAULT_DOMAIN"
          response.headers["Vary"]?.should eq "Origin"
        end

        it "should not add the credentials header" do
          response = client.get("/defaults")
          response.headers["Access-Control-Allow-Credentials"]?.should be_nil
        end

        it "should add the credentials header" do
          response = client.get("/defaults")
          response.headers["Access-Control-Expose-Headers"]?.should eq "DEFAULT1_EH,DEFAULT2_EH"
        end

        it "should not add the allow methods header" do
          response = client.get("/defaults")
          response.headers["Access-Control-Allow-Methods"]?.should be_nil
        end

        it "should not add the allow headers header" do
          response = client.get("/defaults")
          response.headers["Access-Control-Allow-Headers"]?.should be_nil
        end

        it "should not add the max age header" do
          response = client.get("/defaults")
          response.headers["Access-Control-Max-Age"]?.should be_nil
        end

        it "should return the correct response" do
          response = client.get("/defaults")
          response.body.should eq "\"default\""
        end
      end

      describe "OPTIONS" do
        describe "invalid request" do
          describe "with a missing Request-Method header" do
            it "should return the proper error" do
              response = client.options("/defaults")
              response.body.should eq "{\"code\":403,\"message\":\"Preflight request header 'Access-Control-Request-Method' is missing.\"}"
              response.status.should eq HTTP::Status::FORBIDDEN
            end
          end

          describe "with a missing Request-Method header" do
            it "should return the proper error" do
              response = client.options("/defaults", headers: HTTP::Headers{"Access-Control-Request-Method" => "GET"})
              response.body.should eq "{\"code\":403,\"message\":\"Preflight request header 'Access-Control-Request-Headers' is missing.\"}"
              response.status.should eq HTTP::Status::FORBIDDEN
            end
          end

          describe "with an invalid request method" do
            it "should return the proper error" do
              response = client.options("/defaults", headers: HTTP::Headers{"Access-Control-Request-Method" => "POST"})
              response.body.should eq "{\"code\":405,\"message\":\"Request method 'POST' is not allowed.\"}"
              response.status.should eq HTTP::Status::METHOD_NOT_ALLOWED
            end
          end

          describe "with an invalid request header" do
            it "should return the proper error" do
              response = client.options("/defaults", headers: HTTP::Headers{"Access-Control-Request-Method" => "GET", "Access-Control-Request-Headers" => "FOO"})
              response.body.should eq "{\"code\":403,\"message\":\"Request header 'FOO' is not allowed.\"}"
              response.status.should eq HTTP::Status::FORBIDDEN
            end
          end
        end

        it "should add the allow origin header" do
          response = client.options("/defaults", headers: HTTP::Headers{"Access-Control-Request-Method" => "GET", "Access-Control-Request-Headers" => "DEFAULT_AH"})
          response.headers["Access-Control-Allow-Origin"]?.should eq "DEFAULT_DOMAIN"
          response.headers["Vary"]?.should eq "Origin"
        end

        it "should not add the credentials header" do
          response = client.options("/defaults", headers: HTTP::Headers{"Access-Control-Request-Method" => "GET", "Access-Control-Request-Headers" => "DEFAULT_AH"})
          response.headers["Access-Control-Allow-Credentials"]?.should be_nil
        end

        it "should add the credentials header" do
          response = client.options("/defaults", headers: HTTP::Headers{"Access-Control-Request-Method" => "GET", "Access-Control-Request-Headers" => "DEFAULT_AH"})
          response.headers["Access-Control-Expose-Headers"]?.should eq "DEFAULT1_EH,DEFAULT2_EH"
        end

        it "should add the allow methods header" do
          response = client.options("/defaults", headers: HTTP::Headers{"Access-Control-Request-Method" => "GET", "Access-Control-Request-Headers" => "DEFAULT_AH"})
          response.headers["Access-Control-Allow-Methods"]?.should eq "GET"
        end

        it "should add the allow headers header" do
          response = client.options("/defaults", headers: HTTP::Headers{"Access-Control-Request-Method" => "GET", "Access-Control-Request-Headers" => "DEFAULT_AH"})
          response.headers["Access-Control-Allow-Headers"]?.should eq "DEFAULT_AH"
        end

        it "should add the max age header" do
          response = client.options("/defaults", headers: HTTP::Headers{"Access-Control-Request-Method" => "GET", "Access-Control-Request-Headers" => "DEFAULT_AH"})
          response.headers["Access-Control-Max-Age"]?.should eq "123"
        end

        it "should NOT execute the action's handler" do
          response = client.options("/defaults", headers: HTTP::Headers{"Access-Control-Request-Method" => "GET", "Access-Control-Request-Headers" => "DEFAULT_AH"})
          response.body.should eq ""
          response.status.should eq HTTP::Status::OK
        end
      end
    end

    describe "controller overload" do
      it "should add the allow origin header" do
        response = client.get("/class_overload")
        response.headers["Access-Control-Allow-Origin"]?.should eq "OVERLOAD_DOMAIN"
        response.headers["Vary"]?.should eq "Origin"
      end

      it "should not add the credentials header" do
        response = client.get("/class_overload")
        response.headers["Access-Control-Allow-Credentials"]?.should be_nil
      end

      it "should add the credentials header" do
        response = client.get("/class_overload")
        response.headers["Access-Control-Expose-Headers"]?.should eq "DEFAULT1_EH,DEFAULT2_EH"
      end

      it "should not add the allow methods header" do
        response = client.get("/class_overload")
        response.headers["Access-Control-Allow-Methods"]?.should be_nil
      end

      it "should not add the allow headers header" do
        response = client.get("/class_overload")
        response.headers["Access-Control-Allow-Headers"]?.should be_nil
      end

      it "should not add the max age header" do
        response = client.get("/class_overload")
        response.headers["Access-Control-Max-Age"]?.should be_nil
      end

      it "should return the correct response" do
        response = client.get("/class_overload")
        response.body.should eq "\"class_overload\""
      end
    end

    describe "action overload" do
      it "should add the allow origin header" do
        response = client.get("/action_overload")
        response.headers["Access-Control-Allow-Origin"]?.should eq "ACTION_DOMAIN"
        response.headers["Vary"]?.should eq "Origin"
      end

      it "should add the credentials header" do
        response = client.get("/action_overload")
        response.headers["Access-Control-Allow-Credentials"]?.should eq "true"
      end

      it "should add the credentials header" do
        response = client.get("/action_overload")
        response.headers["Access-Control-Expose-Headers"]?.should eq "DEFAULT1_EH,DEFAULT2_EH"
      end

      it "should not add the allow methods header" do
        response = client.get("/action_overload")
        response.headers["Access-Control-Allow-Methods"]?.should be_nil
      end

      it "should not add the allow headers header" do
        response = client.get("/action_overload")
        response.headers["Access-Control-Allow-Headers"]?.should be_nil
      end

      it "should not add the max age header" do
        response = client.get("/action_overload")
        response.headers["Access-Control-Max-Age"]?.should be_nil
      end

      it "should return the correct response" do
        response = client.get("/action_overload")
        response.body.should eq "\"action_overload\""
      end
    end

    describe "disable overload" do
      it "should not add the allow origin header" do
        response = client.get("/disable_overload")
        response.headers["Access-Control-Allow-Origin"]?.should be_nil
        response.headers["Vary"]?.should be_nil
      end

      it "should not add the credentials header" do
        response = client.get("/disable_overload")
        response.headers["Access-Control-Allow-Credentials"]?.should be_nil
      end

      it "should not add the credentials header" do
        response = client.get("/disable_overload")
        response.headers["Access-Control-Expose-Headers"]?.should be_nil
      end

      it "should not add the allow methods header" do
        response = client.get("/disable_overload")
        response.headers["Access-Control-Allow-Methods"]?.should be_nil
      end

      it "should not add the allow headers header" do
        response = client.get("/disable_overload")
        response.headers["Access-Control-Allow-Headers"]?.should be_nil
      end

      it "should not add the max age header" do
        response = client.get("/disable_overload")
        response.headers["Access-Control-Max-Age"]?.should be_nil
      end

      it "should return the correct response" do
        response = client.get("/disable_overload")
        response.body.should eq "\"disable_overload\""
      end
    end

    describe "inheritence" do
      describe "with no overloads" do
        it "should add the allow origin header" do
          response = client.get("/inheritence")
          response.headers["Access-Control-Allow-Origin"]?.should eq "OVERLOAD_DOMAIN"
          response.headers["Vary"]?.should eq "Origin"
        end

        it "should not add the credentials header" do
          response = client.get("/inheritence")
          response.headers["Access-Control-Allow-Credentials"]?.should be_nil
        end

        it "should add the credentials header" do
          response = client.get("/inheritence")
          response.headers["Access-Control-Expose-Headers"]?.should eq "DEFAULT1_EH,DEFAULT2_EH"
        end

        it "should not add the allow methods header" do
          response = client.get("/inheritence")
          response.headers["Access-Control-Allow-Methods"]?.should be_nil
        end

        it "should not add the allow headers header" do
          response = client.get("/inheritence")
          response.headers["Access-Control-Allow-Headers"]?.should be_nil
        end

        it "should not add the max age header" do
          response = client.get("/inheritence")
          response.headers["Access-Control-Max-Age"]?.should be_nil
        end

        it "should return the correct response" do
          response = client.get("/inheritence")
          response.body.should eq "\"inheritence\""
        end
      end

      describe "with a disable overload" do
        it "should not add the allow origin header" do
          response = client.get("/inheritence_overload")
          response.headers["Access-Control-Allow-Origin"]?.should be_nil
          response.headers["Vary"]?.should be_nil
        end

        it "should not add the credentials header" do
          response = client.get("/inheritence_overload")
          response.headers["Access-Control-Allow-Credentials"]?.should be_nil
        end

        it "should not add the credentials header" do
          response = client.get("/inheritence_overload")
          response.headers["Access-Control-Expose-Headers"]?.should be_nil
        end

        it "should not add the allow methods header" do
          response = client.get("/inheritence_overload")
          response.headers["Access-Control-Allow-Methods"]?.should be_nil
        end

        it "should not add the allow headers header" do
          response = client.get("/inheritence_overload")
          response.headers["Access-Control-Allow-Headers"]?.should be_nil
        end

        it "should not add the max age header" do
          response = client.get("/inheritence_overload")
          response.headers["Access-Control-Max-Age"]?.should be_nil
        end

        it "should return the correct response" do
          response = client.get("/inheritence_overload")
          response.body.should eq "\"inheritence_overload\""
        end
      end
    end
  end
end
