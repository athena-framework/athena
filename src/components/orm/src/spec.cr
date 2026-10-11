require "athena-spec"

# A set of testing utilities/types to aid in testing `Athena::ORM` related types.
#
# ### Getting Started
#
# Require this module in your `spec_helper.cr` file.
#
# ```
# # This also requires "spec" and "athena-spec".
# require "athena-orm/spec"
# ```
#
# Add `Athena::Spec` as a development dependency, then run a `shards install`.
# See the individual types for more information.
module Athena::ORM::Spec
  # Base `ASPEC::TestCase` for tests that use the database.
  # Each test runs in a transaction that's rolled back once the test is done, so tests don't see each other's data.
  #
  # Implement `#entity_manager_factory` to return the factory the entity manager of each test is created by, such as in an abstract test case the application's specs share:
  #
  # ```
  # # spec/spec_helper.cr
  # ORM = AORM::EntityManagerFactory.new DB.open ENV["DATABASE_URL"]
  #
  # abstract struct AppDBTestCase < AORM::Spec::DBTestCase
  #   def entity_manager_factory : AORM::EntityManagerFactory
  #     ORM
  #   end
  # end
  #
  # # spec/user_repository_spec.cr
  # struct UserRepositoryTest < AppDBTestCase
  #   def test_find_by_name : Nil
  #     user = User.new
  #     user.name = "George"
  #
  #     self.em.persist user
  #     self.em.flush
  #
  #     self.em.repository(User).find_one_by(name: "George").should be user
  #   end
  # end
  # ```
  #
  # The code under test must use `#em`.
  # Queries on any other connection don't see the test's data, and what they write is committed.
  #
  # TIP: Applications using the ORM through `AORM::Bundle` can instead include `AORM::Spec::DatabaseTransaction` into their test cases.
  #
  # NOTE: MySQL and MariaDB implicitly commit the transaction on statements that change the schema, such as `CREATE TABLE`.
  # PostgreSQL aborts the transaction when a statement fails, so the test's later statements fail too.
  #
  # NOTE: A test case that overrides `#tear_down` must call `super`, which rolls back the transaction.
  abstract struct DBTestCase < ASPEC::TestCase
    # Returns the factory the entity manager of each test is created by.
    abstract def entity_manager_factory : AORM::EntityManagerFactory

    # Returns the entity manager of the current test, on a connection checked out from the pool of the `#entity_manager_factory`, with a transaction begun.
    #
    # It's created the first time it's needed, so tests that don't use it don't check out a connection.
    getter em : AORM::EntityManager do
      factory = self.entity_manager_factory
      connection = factory.database.checkout

      begin
        em = factory.create_entity_manager connection
        em.begin_transaction
        em
      rescue ex
        connection.release
        raise ex
      end
    end

    # Closes the entity manager of the current test, if one was created, rolling back its transaction and returning its connection to the pool.
    def tear_down : Nil
      super

      return unless em = @em

      @em = nil

      begin
        em.close

        while em.connection.transaction_active?
          em.rollback
        end
      ensure
        em.connection.wrapped.release
      end
    end
  end

  # Runs each test of an [ADI::Spec::ContainerTestCase](/DependencyInjection/Spec/ContainerTestCase/) in a transaction that's rolled back once the test is done, for applications using the ORM through `AORM::Bundle`.
  #
  # ```
  # struct UserControllerTest < ATH::Spec::APITestCase
  #   include AORM::Spec::DatabaseTransaction
  #
  #   def test_show : Nil
  #     user = User.new
  #     user.name = "George"
  #
  #     self.em.persist user
  #     self.em.flush
  #
  #     self.get("/user/#{user.id}").body.should contain "George"
  #   end
  # end
  # ```
  #
  # `#em` is the entity manager the test's container injects, so the services the test uses, and the requests an [ATH::Spec::APITestCase](/Framework/Spec/APITestCase/) makes, run within the test's transaction.
  # It's cleared after each request, so the next request and the test itself load entities from the database again, see `AORM::Bundle::Registry#reset`.
  # The transaction is rolled back once the test is done, when its container closes the entity manager, see `AORM::Bundle::Registry#close`.
  #
  # NOTE: MySQL and MariaDB implicitly commit the transaction on statements that change the schema, such as `CREATE TABLE`.
  # PostgreSQL aborts the transaction when a statement fails, so the test's later statements fail too.
  #
  # NOTE: A test case that overrides `#tear_down` must call `super`, which closes the entity manager.
  module DatabaseTransaction
    macro included
      {% unless @type.ancestors.any?(&.name.==("Athena::DependencyInjection::Spec::ContainerTestCase")) %}
        {% @type.raise "'AORM::Spec::DatabaseTransaction' must be included into an 'ADI::Spec::ContainerTestCase', which '#{@type}' isn't." %}
      {% end %}
    end

    def initialize
      super

      # Begun before the test makes any request, so that what the requests write is rolled back too.
      self.em.begin_transaction
    end

    # Returns the entity manager of the current test, which the test's container injects, with the test's transaction begun.
    def em : AORM::EntityManager
      self.container.athena_orm_registry.manager
    end
  end
end
