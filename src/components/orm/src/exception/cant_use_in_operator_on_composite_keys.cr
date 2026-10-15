require "./persister"

# Raised when entities are searched for by several entities of an association whose target has a composite primary key.
class Athena::ORM::Exception::CantUseInOperatorOnCompositeKeys < Athena::ORM::Exception::Persister
  def self.create : self
    new "Can't use IN operator on entities that have composite keys."
  end
end
