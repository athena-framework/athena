require "../spec_helper"

describe AMC::TokenFactory::DefaultClaims do
  it "merges in the default claims" do
    grants = [AMC::Grant.new(:subscribe, ["a"])]

    decorated = AMC::Spec::AssertingTokenFactory.new "JWT", grants, {"iss" => "https://example.com", "sub" => "default-sub"}

    AMC::TokenFactory::DefaultClaims
      .new(decorated, {"iss" => "https://example.com", "sub" => "default-sub"} of String => String | Array(String))
      .create(grants).should eq "JWT"

    decorated.called?.should be_true
  end

  it "allows overriding the default claims" do
    grants = [AMC::Grant.new(:subscribe, ["a"])]

    decorated = AMC::Spec::AssertingTokenFactory.new "JWT", grants, {"iss" => "https://example.com", "sub" => "per-request-sub"}

    AMC::TokenFactory::DefaultClaims
      .new(decorated, {"iss" => "https://example.com", "sub" => "default-sub"} of String => String | Array(String))
      .create(grants, {"sub" => "per-request-sub"}).should eq "JWT"

    decorated.called?.should be_true
  end
end
