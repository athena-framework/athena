# A set of testing utilities/types to aid in testing `Athena::DependencyInjection` related types.
#
# ### Getting Started
#
# Require this module in your `spec_helper.cr` file.
#
# ```
# # This also requires "spec".
# require "athena-dependency_injection/spec"
# ```
module Athena::DependencyInjection::Spec
  # A mock implementation of `ADI::ServiceContainer` that be used within a testing context to allow for mocking out services without affecting the actual container outside of tests.
  #
  # An example of this is when integration testing service based [ATH::Controller][Athena::Framework::Controller]s.
  # Service dependencies that interact with an external source, like a third party API or a database, should most likely be mocked out.
  # However your other services should be left as is in order to get the most benefit from the test.
  #
  # ## Mocking
  #
  # The `ADI::ServiceContainer` is nothing more than a normal Crystal class with some instance variables and methods.
  # As such, mocking services is as easy as monkey patching `self` with the mocked versions, assuming of course they are of a compatible type.
  #
  # Given Crystal's lack of a robust mocking shard, it isn't as straightforward as other languages.
  # The best way at the moment is either using inheritance or interfaces (modules) to manually create a concrete test class/struct;
  # with the latter option being preferred as it would work for both structs and classes.
  #
  # For example, we can create a mock implementation of a type by extending it:
  # ```
  # class MockMyService < MyService
  #   def get_value
  #     # Can now just return a static expected value.
  #     # Test properties/constructor(s) can also be added to make it a bit more generic.
  #     1234
  #   end
  # end
  # ```
  #
  # Because our mock extends `MyService`, it is a compatible type for anything typed as `MyService`.
  #
  # Another way to handle mocking is via interfaces (modules).
  #
  # ```
  # module SomeInterface; end
  #
  # struct MockMyService
  #   include SomeInterface
  # end
  # ```
  #
  # Because our mock implements `SomeInterface`, it is a compatible type for anything typed as `SomeInterface`.
  #
  # NOTE: Service mocks do not need to registered as services themselves since they will need to be configured manually.
  # NOTE: The `type` argument as part of the `ADI::Register` annotation can be used to set the type of a service within the container.
  # See `ADI::Register@customizing-services-type` for more details.
  #
  # ### Dynamic Mocks
  #
  # A dynamic mock consists of adding a `setter` to `self` that allows setting the mocked service dynamically at runtime,
  # while keeping the original up until if/when it is replaced.
  #
  # ```
  # class ADI::Spec::MockableServiceContainer
  #   # The setter should be nilable as they're lazily initialized within the container.
  #   setter my_service : MyServiceInterface?
  # end
  #
  # # ...
  #
  # # Now the `my_service` service can be replaced at runtime.
  # mock_container.my_service = MockMyService.new
  #
  # # ...
  # ```
  #
  # ### Global Mocks
  #
  # Global mocks totally replace the original service, i.e. always return the mocked service.
  #
  # ```
  # class ADI::Spec::MockableServiceContainer
  #   # Global mocks should use the block based `getter` macro.
  #   getter my_service : MyServiceInterface { MockMyService.new }
  # end
  #
  # # `MockMyService` will now be injected across the board when using `self`.
  # # ...
  # ```
  #
  # ### Hybrid Mocks
  #
  # Dynamic and Global mocking can also be combined to allow having a default mock, but allow overriding if/when needed.
  # This can be accomplished by adding both a getter and setter to `self.`
  #
  # ```
  # class ADI::Spec::MockableServiceContainer
  #   # Hybrid mocks should use the block based `property` macro.
  #   property my_service : MyServiceInterface { DefaultMockService.new }
  # end
  #
  # # ...
  #
  # # `DefaultMockService` will now be injected across the board by when using `self`.
  #
  # # But can still be replaced at runtime.
  # mock_container.my_service = CustomMockService.new
  #
  # # ...
  # ```
  class MockableServiceContainer < ADI::ServiceContainer; end
end
