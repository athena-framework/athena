require "./routing_spec_helper"

do_with_config(CORS_CONFIG) do
  describe Athena::Routing::Handlers::CorsHandler do
    describe "defaults" do
      describe "GET" do
        it "should add the allow origin header" do
          response = CLIENT.get("/defaults")
          response.headers["Access-Control-Allow-Origin"]?.should eq "DEFAULT_DOMAIN"
          response.headers["Vary"]?.should eq "Origin"
        end

        it "should not add the credentials header" do
          response = CLIENT.get("/defaults")
          response.headers["Access-Control-Allow-Credentials"]?.should be_nil
        end

        it "should add the credentials header" do
          response = CLIENT.get("/defaults")
          response.headers["Access-Control-Expose-Headers"]?.should eq "DEFAULT1_EH,DEFAULT2_EH"
        end

        it "should not add the allow methods header" do
          response = CLIENT.get("/defaults")
          response.headers["Access-Control-Allow-Methods"]?.should be_nil
        end

        it "should not add the allow headers header" do
          response = CLIENT.get("/defaults")
          response.headers["Access-Control-Allow-Headers"]?.should be_nil
        end

        it "should not add the max age header" do
          response = CLIENT.get("/defaults")
          response.headers["Access-Control-Max-Age"]?.should be_nil
        end
      end

      describe "OPTIONS" do
        describe "invalid request" do
          describe "with a missing Request-Method header" do
            it "should return the proper error" do
              response = CLIENT.options("/defaults")
              response.body.should eq "{\"code\":403,\"message\":\"Preflight request header 'Access-Control-Request-Method' is missing.\"}"
              response.status_code.should eq 403
            end
          end

          describe "with a missing Request-Method header" do
            it "should return the proper error" do
              response = CLIENT.options("/defaults", headers: HTTP::Headers{"Access-Control-Request-Method" => "GET"})
              response.body.should eq "{\"code\":403,\"message\":\"Preflight request header 'Access-Control-Request-Headers' is missing.\"}"
              response.status_code.should eq 403
            end
          end

          describe "with an invalid request method" do
            it "should return the proper error" do
              response = CLIENT.options("/defaults", headers: HTTP::Headers{"Access-Control-Request-Method" => "POST"})
              response.body.should eq "{\"code\":405,\"message\":\"Request method 'POST' is not allowed.\"}"
              response.status_code.should eq 405
            end
          end

          describe "with an invalid request header" do
            it "should return the proper error" do
              response = CLIENT.options("/defaults", headers: HTTP::Headers{"Access-Control-Request-Method" => "GET", "Access-Control-Request-Headers" => "FOO"})
              response.body.should eq "{\"code\":403,\"message\":\"Request header 'FOO' is not allowed.\"}"
              response.status_code.should eq 403
            end
          end
        end

        it "should add the allow origin header" do
          response = CLIENT.options("/defaults", headers: HTTP::Headers{"Access-Control-Request-Method" => "GET", "Access-Control-Request-Headers" => "DEFAULT_AH"})
          response.headers["Access-Control-Allow-Origin"]?.should eq "DEFAULT_DOMAIN"
          response.headers["Vary"]?.should eq "Origin"
        end

        it "should not add the credentials header" do
          response = CLIENT.options("/defaults", headers: HTTP::Headers{"Access-Control-Request-Method" => "GET", "Access-Control-Request-Headers" => "DEFAULT_AH"})
          response.headers["Access-Control-Allow-Credentials"]?.should be_nil
        end

        it "should add the credentials header" do
          response = CLIENT.options("/defaults", headers: HTTP::Headers{"Access-Control-Request-Method" => "GET", "Access-Control-Request-Headers" => "DEFAULT_AH"})
          response.headers["Access-Control-Expose-Headers"]?.should eq "DEFAULT1_EH,DEFAULT2_EH"
        end

        it "should add the allow methods header" do
          response = CLIENT.options("/defaults", headers: HTTP::Headers{"Access-Control-Request-Method" => "GET", "Access-Control-Request-Headers" => "DEFAULT_AH"})
          response.headers["Access-Control-Allow-Methods"]?.should eq "GET"
        end

        it "should add the allow headers header" do
          response = CLIENT.options("/defaults", headers: HTTP::Headers{"Access-Control-Request-Method" => "GET", "Access-Control-Request-Headers" => "DEFAULT_AH"})
          response.headers["Access-Control-Allow-Headers"]?.should eq "DEFAULT_AH"
        end

        it "should not the max age header" do
          response = CLIENT.options("/defaults", headers: HTTP::Headers{"Access-Control-Request-Method" => "GET", "Access-Control-Request-Headers" => "DEFAULT_AH"})
          response.headers["Access-Control-Max-Age"]?.should eq "123"
        end
      end
    end

    describe "controller overload" do
      it "should add the allow origin header" do
        response = CLIENT.get("/class_overload")
        response.headers["Access-Control-Allow-Origin"]?.should eq "OVERLOAD_DOMAIN"
        response.headers["Vary"]?.should eq "Origin"
      end

      it "should not add the credentials header" do
        response = CLIENT.get("/class_overload")
        response.headers["Access-Control-Allow-Credentials"]?.should be_nil
      end

      it "should add the credentials header" do
        response = CLIENT.get("/class_overload")
        response.headers["Access-Control-Expose-Headers"]?.should eq "DEFAULT1_EH,DEFAULT2_EH"
      end

      it "should not add the allow methods header" do
        response = CLIENT.get("/class_overload")
        response.headers["Access-Control-Allow-Methods"]?.should be_nil
      end

      it "should not add the allow headers header" do
        response = CLIENT.get("/class_overload")
        response.headers["Access-Control-Allow-Headers"]?.should be_nil
      end

      it "should not add the max age header" do
        response = CLIENT.get("/class_overload")
        response.headers["Access-Control-Max-Age"]?.should be_nil
      end
    end

    describe "action overload" do
      it "should add the allow origin header" do
        response = CLIENT.get("/action_overload")
        response.headers["Access-Control-Allow-Origin"]?.should eq "ACTION_DOMAIN"
        response.headers["Vary"]?.should eq "Origin"
      end

      it "should not add the credentials header" do
        response = CLIENT.get("/action_overload")
        response.headers["Access-Control-Allow-Credentials"]?.should eq "true"
      end

      it "should add the credentials header" do
        response = CLIENT.get("/action_overload")
        response.headers["Access-Control-Expose-Headers"]?.should eq "DEFAULT1_EH,DEFAULT2_EH"
      end

      it "should not add the allow methods header" do
        response = CLIENT.get("/action_overload")
        response.headers["Access-Control-Allow-Methods"]?.should be_nil
      end

      it "should not add the allow headers header" do
        response = CLIENT.get("/action_overload")
        response.headers["Access-Control-Allow-Headers"]?.should be_nil
      end

      it "should not add the max age header" do
        response = CLIENT.get("/action_overload")
        response.headers["Access-Control-Max-Age"]?.should be_nil
      end
    end

    describe "disable overload" do
      it "should add the allow origin header" do
        response = CLIENT.get("/disable_overload")
        response.headers["Access-Control-Allow-Origin"]?.should be_nil
        response.headers["Vary"]?.should be_nil
      end

      it "should not add the credentials header" do
        response = CLIENT.get("/disable_overload")
        response.headers["Access-Control-Allow-Credentials"]?.should be_nil
      end

      it "should add the credentials header" do
        response = CLIENT.get("/disable_overload")
        response.headers["Access-Control-Expose-Headers"]?.should be_nil
      end

      it "should not add the allow methods header" do
        response = CLIENT.get("/disable_overload")
        response.headers["Access-Control-Allow-Methods"]?.should be_nil
      end

      it "should not add the allow headers header" do
        response = CLIENT.get("/disable_overload")
        response.headers["Access-Control-Allow-Headers"]?.should be_nil
      end

      it "should not add the max age header" do
        response = CLIENT.get("/disable_overload")
        response.headers["Access-Control-Max-Age"]?.should be_nil
      end
    end
  end
end
