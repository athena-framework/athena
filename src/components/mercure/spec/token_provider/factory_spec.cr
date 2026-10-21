require "../spec_helper"

describe AMC::TokenProvider::Factory do
  it "returns the token" do
    AMC::TokenProvider::Factory
      .new(
        AMC::TokenFactory::JWT.new("looooooooooooongenoughtestsecret", jwt_lifetime: nil, protocol_version: :legacy),
        [AMC::Grant.new(:publish, ["*"]), AMC::Grant.new(:subscribe, [] of String)],
      )
      .jwt.should eq "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJtZXJjdXJlIjp7InB1Ymxpc2giOlsiKiJdLCJzdWJzY3JpYmUiOltdfX0.ZTK3JhEKO1338LAgRMw6j0lkGRMoaZtU4EtGiAylAns" # spellchecker:disable-line
  end

  it "passes the grants and additional claims to the factory" do
    grants = [AMC::Grant.new(:publish, ["*"])]

    AMC::TokenProvider::Factory
      .new(AMC::Spec::AssertingTokenFactory.new("JWT", grants, {"aud" => "https://example.com"}), grants, {"aud" => "https://example.com"} of String => String | Array(String))
      .jwt.should eq "JWT"
  end
end
