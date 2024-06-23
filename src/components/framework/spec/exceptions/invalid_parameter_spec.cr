require "../spec_helper"

describe ATH::Exception::InvalidParameter do
  describe ".with_violations" do
    it "builds the message and exposes the param and violations" do
      violation = AVD::Violation::ConstraintViolation.new(
        "ERROR",
        "ERROR",
        Hash(String, String).new,
        nil,
        "",
        AVD::ValueContainer.new(nil),
      )

      errors = AVD::Violation::ConstraintViolationList.new [violation] of AVD::Violation::ConstraintViolationInterface
      param = ATH::Params::QueryParam(Int32?).new("id")

      exception = ATH::Exception::InvalidParameter.with_violations param, errors

      exception.message.should eq "Parameter 'id' is invalid."
      exception.status.should eq HTTP::Status::UNPROCESSABLE_ENTITY
      exception.violations.should eq errors
      exception.parameter.name.should eq "id"
    end
  end
end
