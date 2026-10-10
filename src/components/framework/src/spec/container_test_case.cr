# Base `ASPEC::TestCase` for tests that use the service container, such as integration tests of services.
#
# Each test has its own `ADI::Spec::MockableServiceContainer`, see `#container`.
# Once the test is done, its `ACTR::Service::Closeable` services are closed, as they would be once a request is done.
#
# ```
# @[ADI::Register(public: true)]
# class GreetingService
#   def greet(name : String) : String
#     "Hello #{name}!"
#   end
# end
#
# struct GreetingServiceTest < ATH::Spec::ContainerTestCase
#   def test_greet : Nil
#     self.container.greeting_service.greet("George").should eq "Hello George!"
#   end
# end
# ```
#
# TIP: See `ADI::Spec::MockableServiceContainer` for how to replace services within the container.
#
# NOTE: A test case that overrides `#tear_down` must call `super`, which closes the services.
abstract struct Athena::Framework::Spec::ContainerTestCase < ASPEC::TestCase
  def initialize
    # Ensure each test method has a unique container.
    self.init_container
  end

  # Returns the service container of the current test.
  def container : ADI::Spec::MockableServiceContainer
    ADI.container.as(ADI::Spec::MockableServiceContainer)
  end

  # Closes the `ACTR::Service::Closeable` services of the current test.
  def tear_down : Nil
    self.container.athena_framework_services_closer.close

    super
  end

  # Helper method to init the container.
  # Creates a new container instance and assigns it to the current fiber.
  protected def init_container : Nil
    Fiber.current.container = ADI::Spec::MockableServiceContainer.new
  end
end
