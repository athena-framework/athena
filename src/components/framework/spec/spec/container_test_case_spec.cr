require "../spec_helper"

@[ADI::Register]
class ContainerTestCaseCloseable
  include ACTR::Service::Closeable

  class_getter closes = 0

  def close : Nil
    @@closes += 1
  end
end

@[ASPEC::TestCase::Skip]
private struct MockContainerTestCase < ATH::Spec::ContainerTestCase; end

struct ContainerTestCaseTest < ASPEC::TestCase
  def test_each_test_has_its_own_container : Nil
    first = MockContainerTestCase.new.container
    second = MockContainerTestCase.new.container

    first.should_not be second
  end

  def test_container_is_the_container_of_the_current_fiber : Nil
    MockContainerTestCase.new.container.should be ADI.container
  end

  def test_tear_down_closes_closeable_services : Nil
    closes = ContainerTestCaseCloseable.closes

    MockContainerTestCase.new.tear_down

    ContainerTestCaseCloseable.closes.should eq closes + 1
  end
end
