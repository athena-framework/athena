require "../spec_helper"

record NotAService, id : Int32 = 1234

@[ADI::Register(public: true)]
class SomeUntypedService
  getter service : NotAService

  def initialize(@service = NotAService.new); end
end

describe ADI::ServiceContainer do
  it "when the constructor arg is not typed, but has a default" do
    ADI::ServiceContainer.new.some_untyped_service.service.id.should eq 1234
  end
end
