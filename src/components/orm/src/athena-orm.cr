require "db"
require "athena-contracts/event_dispatcher"

require "./collection/*"
require "./exceptions/*"
require "./events/*"
require "./internal/**"
require "./id/*"
require "./mapping/annotations"
require "./mapping/**"
require "./persisters/entity/*"
require "./persisters/collection/*"
require "./platforms/*"
require "./query/*"
require "./schema/*"
require "./sql/parser"
require "./types/*"
require "./utility/*"

require "./annotations"
require "./driver"
require "./driver_manager"
require "./connection"
require "./default_repository_factory"
require "./entity"
require "./proxy"
require "./entity_manager"
require "./entity_manager_factory"
require "./entity_repository"
require "./listeners_invoker"
require "./native_query"
require "./persister_helper"
require "./unit_of_work"

# Convenience alias to make referencing `Athena::ORM` types easier.
alias AORM = Athena::ORM

# Convenience alias to make referencing `AORM::Annotations` types easier.
alias AORMA = Athena::ORM::Annotations

# Provides an annotation driven object-relational mapper that persists Crystal objects to a relational database.
module Athena::ORM
  VERSION = "0.1.0"

  # Contains the events emitted during the lifecycle of an entity and of a flush, see `AORM::Events::EventArgs`.
  module Events; end

  # Contains the exceptions raised by the ORM.
  module Exceptions; end

  # Contains the database platforms, which account for the differences between databases, see `AORM::Platforms::Platform`.
  module Platforms; end

  # Contains the types describing a database's schema.
  module Schema; end

  # :nodoc:
  module ID; end

  # :nodoc:
  module Internal; end

  # :nodoc:
  module Internal::Hydrators; end

  # :nodoc:
  module Persisters; end

  # :nodoc:
  module Persisters::Collection; end

  # :nodoc:
  module Persisters::Entity; end

  # :nodoc:
  module Utility; end

  # The lock to acquire on a row when loading an entity, such as via `AORM::EntityManager#find`.
  #
  # TODO: Row locking isn't supported yet, so `None` is the only mode.
  # A `lock_version` only applies to optimistic locking, so it's ignored.
  enum LockMode
    # Doesn't lock the row.
    None
  end

  # :nodoc:
  enum HydrationMode
    Object
    SimpleObject
  end
end
