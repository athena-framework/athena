require "../spec_helper"

describe AMC::TokenProvider::Static do
  it "returns the token" do
    AMC::TokenProvider::Static.new("FOO").jwt.should eq "FOO"
  end
end
