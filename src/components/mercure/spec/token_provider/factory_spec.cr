require "../spec_helper"

describe AMC::TokenProvider::Factory do
  it "returns the token" do
    AMC::TokenProvider::Factory
      .new(
        AMC::TokenFactory::JWT.new("looooooooooooongenoughtestsecret", jwt_lifetime: nil),
        [] of String,
        ["*"]
      )
      .jwt.should eq "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJtZXJjdXJlIjp7InB1Ymxpc2giOlsiKiJdLCJzdWJzY3JpYmUiOltdfX0.ZTK3JhEKO1338LAgRMw6j0lkGRMoaZtU4EtGiAylAns"
  end
end
