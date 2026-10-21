require "../spec_helper"

struct PersisterExceptionsTest < ASPEC::TestCase
  def test_cant_use_in_operator_on_composite_keys : Nil
    exception = AORM::Exception::CantUseInOperatorOnCompositeKeys.create

    exception.should be_a AORM::Exception::Persister
    exception.message.should eq "Can't use IN operator on entities that have composite keys."
  end
end
