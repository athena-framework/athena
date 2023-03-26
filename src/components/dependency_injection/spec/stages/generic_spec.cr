require "../spec_helper"

@[ADI::Register(Int32, Bool, public: true, name: "int_service")]
@[ADI::Register(Float64, Bool, public: true, name: "float_service")]
struct GenericServiceBase(T, B)
  def type
    {T, B}
  end
end

describe ADI::ServiceContainer do
  describe "with a generic service" do
    it "correctly initializes the service with the given generic arguments" do
      ADI.container.int_service.type.should eq({Int32, Bool})
      ADI.container.float_service.type.should eq({Float64, Bool})
    end
  end
end
