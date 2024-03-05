require "../spec_helper"

describe AMC::TokenProvider::Callable do
  it "block overload" do
    provider = AMC::TokenProvider::Callable.new do
      "FOO"
    end

    provider.jwt.should eq "FOO"
  end

  it "proc overload" do
    AMC::TokenProvider::Callable.new(->{ "BAR" }).jwt.should eq "BAR"
  end
end
