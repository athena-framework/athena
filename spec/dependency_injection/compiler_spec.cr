require "./dependency_injection_spec_helper"

describe Athena::DI do
  describe Athena::DI::ServiceContainer do
    describe "compiler errors" do
      describe "when trying to access a private service directly" do
        it "should not compile" do
          assert_error "dependency_injection/compiler/private_service.cr", "private method 'store' called for Athena::DI::ServiceContainer"
        end
      end

      describe "when a service includes the module but is missing the annotation" do
        it "should not compile" do
          assert_error "dependency_injection/compiler/missing_annotation.cr", "TheService includes `ADI::Service` but is not registered.  Did you forget the annotation?"
        end
      end

      describe "when a service has a non optional service dependency but it could not be resolved" do
        it "should not compile" do
          assert_error "dependency_injection/compiler/missing_non_optional_service.cr", "Could not resolve dependency 'the_service' for service 'Klass'.  Did you forget to include `ADI::Service` or declare it optional?"
        end
      end
    end
  end
end
