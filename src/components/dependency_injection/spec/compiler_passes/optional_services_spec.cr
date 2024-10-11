require "../spec_helper"

struct OptionalMissingService
end

@[ADI::Register]
struct OptionalExistingService
end

@[ADI::Register(public: true)]
class OptionalClient
  getter service_missing, service_existing, service_default

  def initialize(
    @service_missing : OptionalMissingService?,
    @service_existing : OptionalExistingService?,
    @service_default : OptionalMissingService | Int32 | Nil = 12,
  ); end
end

describe ADI::ServiceContainer do
  describe "where a dependency is optional" do
    describe "and does not exist" do
      describe "without a default value" do
        it "should inject `nil`" do
          ADI.container.optional_client.service_missing.should be_nil
        end
      end

      describe "with a default value" do
        it "should inject the default" do
          ADI.container.optional_client.service_default.should eq 12
        end
      end
    end

    describe "and does exist" do
      it "should inject that service" do
        ADI.container.optional_client.service_existing.should be_a OptionalExistingService
      end
    end
  end
end
