require "../spec_helper"

describe ATH::Exceptions::Unauthorized do
  describe "#initialize" do
    it "sets the message, status, and headers" do
      exception = ATH::Exceptions::Unauthorized.new "MESSAGE", "CHALLENGE"
      exception.headers.should eq HTTP::Headers{"www-authenticate" => "CHALLENGE"}
      exception.status.should eq HTTP::Status::UNAUTHORIZED
      exception.message.should eq "MESSAGE"
    end
  end
end
