require "../spec_helper"

# 1. Unused private service - will be removed
@[ADI::Register]
class RemoveUnusedService
end

# 2. Used private service - should NOT be removed
@[ADI::Register]
class RemoveUsedService
  def value
    10
  end
end

@[ADI::Register(public: true)]
class RemoveUsedClient
  def initialize(@dep : RemoveUsedService)
  end

  def value
    @dep.value
  end
end

# 3. Public alias target - should NOT be removed
module RemoveTestInterface; end

@[ADI::Register]
@[ADI::AsAlias("remove_test_alias", public: true)]
class RemoveAliasedService
  include RemoveTestInterface

  def value
    20
  end
end

describe ADI::ServiceContainer::RemoveUnusedServices do
  it "keeps referenced private services" do
    ADI.container.remove_used_client.value.should eq 10
  end

  it "keeps services with public aliases" do
    ADI.container.remove_test_alias.value.should eq 20
  end
end
