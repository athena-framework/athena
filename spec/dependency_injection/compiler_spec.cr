require "./dependency_injection_spec_helper"

describe Athena::DI do
  describe Athena::DI::ServiceContainer do
    describe "when trying to access a private service directly" do
      it "should not compile" do
        assert_error "dependency_injection/compiler/private_service.cr", "private method 'store' called for Athena::DI::ServiceContainer"
      end
    end
  end
end
