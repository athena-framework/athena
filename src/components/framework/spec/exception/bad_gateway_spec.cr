require "../spec_helper"

describe ATH::Exception::BadGateway do
  describe "#initialize" do
    it "sets the message, and status" do
      exception = ATH::Exception::BadGateway.new "MESSAGE"
      exception.headers.should be_empty
      exception.status.should eq HTTP::Status::BAD_GATEWAY
      exception.message.should eq "MESSAGE"
    end
  end
end
