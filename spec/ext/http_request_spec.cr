require "../spec_helper"

describe HTTP::Request do
  it "#safe?" do
    HTTP::Request.new("GET", "/").safe?.should be_true
    HTTP::Request.new("HEAD", "/").safe?.should be_true
    HTTP::Request.new("OPTIONS", "/").safe?.should be_true
    HTTP::Request.new("TRACE", "/").safe?.should be_true
    HTTP::Request.new("POST", "/").safe?.should be_false
    HTTP::Request.new("PUT", "/").safe?.should be_false
  end
end
