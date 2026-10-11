require "./spec_helper"
require "athena-dependency_injection/spec"
require "../../src/spec"

@[ASPEC::TestCase::Skip]
struct MockDatabaseTransactionTestCase < ADI::Spec::ContainerTestCase
  include AORM::Spec::DatabaseTransaction
end

struct DatabaseTransactionTest < ASPEC::TestCase
  @test_case : MockDatabaseTransactionTestCase

  def initialize
    @test_case = MockDatabaseTransactionTestCase.new
  end

  def tear_down : Nil
    @test_case.tear_down
  end

  def test_initialize_begins_a_transaction_on_the_entity_manager_of_the_container : Nil
    em = @test_case.em

    em.should be @test_case.container.athena_orm_registry.manager
    em.connection.transaction_nesting_level.should eq 1
  end

  # The requests of a test reset the container's services between them.
  def test_transaction_outlives_resetting_the_container_services : Nil
    em = @test_case.em
    group = CmsGroup.new
    group.name = "admins"
    em.persist group

    @test_case.container.athena_dependency_injection_services_resetter.reset

    em.contains(group).should be_false
    em.connection.transaction_nesting_level.should eq 1
  end

  def test_tear_down_rolls_back_every_transaction_and_releases_the_connection : Nil
    em = @test_case.em
    connection = em.connection.wrapped.as PooledMockConnection
    em.begin_transaction
    released = PooledMockConnection.released

    @test_case.tear_down

    em.connection.transaction_active?.should be_false
    connection.executed_statements.last.first.should eq "ROLLBACK"
    em.closed?.should be_true
    PooledMockConnection.released.should eq released + 1
  end

  def test_requires_a_container_test_case : Nil
    ASPEC::Methods.assert_compile_time_error "'AORM::Spec::DatabaseTransaction' must be included into an 'ADI::Spec::ContainerTestCase', which 'PlainTestCase' isn't.", <<-'CR', preamble: %(require "./spec_helper.cr"\nrequire "athena-dependency_injection/spec"\nrequire "../../src/spec")
      struct PlainTestCase < ASPEC::TestCase
        include AORM::Spec::DatabaseTransaction
      end
    CR
  end
end
