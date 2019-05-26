require "./config_spec_helper"

struct SubObject
  include CrSerializer(YAML)

  getter username : String
  getter password : String

  def get_auth_header
    Base64.strict_encode("#{@username}:#{@password}")
  end
end

struct CustomSettings
  getter aws_key : String
  getter sub_object : SubObject
end

describe Athena::Config::Config do
  describe "with custom settings" do
    it "should return the property" do
      config = Athena.config "spec/config/athena.yml"
      config.custom_settings.aws_key.should eq "abc123"
    end

    it "should support nested types" do
      config = Athena.config "spec/config/athena.yml"
      config.custom_settings.sub_object.username.should eq "username"
      config.custom_settings.sub_object.password.should eq "password"
    end

    it "should support methods" do
      config = Athena.config "spec/config/athena.yml"
      config.custom_settings.sub_object.get_auth_header.should eq "dXNlcm5hbWU6cGFzc3dvcmQ="
    end

    describe "when in another env" do
      ENV["ATHENA_ENV"] = "test"

      it "should use the custom settings of that env" do
        config = Athena.config "spec/config/athena.yml"
        config.custom_settings.aws_key.should eq "test_key"
      end
    end
  end
end
