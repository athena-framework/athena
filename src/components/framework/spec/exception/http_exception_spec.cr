require "../spec_helper"

describe ATH::Exception::HTTPException do
  describe "#initialize" do
    it "sets the message, and status" do
      exception = ATH::Exception::HTTPException.new 200, "MESSAGE"
      exception.headers.should be_empty
      exception.status.should eq HTTP::Status::OK
      exception.message.should eq "MESSAGE"
    end
  end
end
