require "./spec_helper"

@[AORMA::Entity]
class TransactionalFixture < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property id : String? = nil

  def initialize(@id : String); end
end

# Fails every INSERT, so a flush raises partway through its transaction.
class FailingInsertPersister < MockEntityPersister
  def execute_inserts : Nil
    raise "insert failed"
  end
end

struct EntityManagerTransactionTest < ASPEC::TestCase
  @connection : MockConnection
  @em : MockEntityManager
  @uow : MockUnitOfWork

  def initialize
    @connection = MockConnection.new
    @em = MockEntityManager.new @connection
    @uow = MockUnitOfWork.new @em
    @em.uow_mock = @uow
  end

  def test_wrap_in_transaction_flushes_commits_and_returns_the_block_value : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata(TransactionalFixture)
    @uow.set_entity_persister TransactionalFixture, persister

    entity = TransactionalFixture.new "a"

    result = @em.wrap_in_transaction do |em|
      em.persist entity
      :done
    end

    result.should eq :done
    persister.inserts.should eq [entity]
    @em.connection.transaction_active?.should be_false

    # The flush runs inside the outer transaction as a savepoint.
    @connection.built_statements.map(&.split.first).should eq %w(BEGIN SAVEPOINT RELEASE COMMIT)
  end

  def test_wrap_in_transaction_rolls_back_and_closes_when_the_block_raises : Nil
    expect_raises Exception, "boom" do
      @em.wrap_in_transaction { raise "boom" }
    end

    @em.closed?.should be_true
    @em.connection.transaction_active?.should be_false
    @connection.built_statements.last.should eq "ROLLBACK"
  end

  # A failed flush only rolls back its own savepoint, leaving the caller's transaction for the caller to end.
  def test_failed_flush_in_an_explicit_transaction_keeps_the_outer_transaction : Nil
    @uow.set_entity_persister TransactionalFixture, FailingInsertPersister.new(@em, @em.class_metadata(TransactionalFixture))

    @em.begin_transaction
    @em.persist TransactionalFixture.new "a"

    expect_raises Exception, "insert failed" do
      @em.flush
    end

    @em.closed?.should be_true
    @em.connection.transaction_nesting_level.should eq 1
    @connection.built_statements.last.should start_with "ROLLBACK TO "

    @em.rollback
    @em.connection.transaction_active?.should be_false
  end

  def test_close_does_not_end_an_open_transaction : Nil
    @em.begin_transaction
    @em.close

    @em.connection.transaction_active?.should be_true
  end
end
