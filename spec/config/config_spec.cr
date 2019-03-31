require "./config_spec_helper"

describe Athena::Config::Config do
  it "should print correctly" do
    Athena::Config::Config.new.to_yaml.should eq <<-YAML
---
routing:
  cors:
    enabled: false
    strategy: blacklist
    defaults: &defaults
      allow_origin: https://yourdomain.com
      expose_headers: []
      max_age: 0
      allow_credentials: false
      allow_methods: []
      allow_headers: []
    groups: {}\n
YAML
  end
end
