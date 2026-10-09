require "./repository_interface"

# Finds entities of type `EntityType` by simple conditions.
# Obtained via `AORM::EntityManager#repository`:
#
# ```
# repository = em.repository User
#
# repository.find 1                     # => #<User:0x7f3a1c2b5e40 @id=1, @name="George">
# repository.find_by name: "George"     # => [#<User:0x7f3a1c2b5e40 @id=1, @name="George">]
# repository.find_one_by name: "Nobody" # => nil
# repository.count active: true         # => 1
# ```
#
# Entities found by a repository go through the identity map, so an entity that's already loaded is returned as is.
#
# ## Criteria
#
# The finders filter on equality of every given field, combined with `AND`.
# Criteria may be given as keyword arguments, which are checked at compile time against the entity's `AORMA::Column` instance variables and their types:
#
# ```
# repository.find_by name: "George", active: true
# repository.find_by nmae: "George" # Error: Unknown field 'nmae' for entity type User. # spellchecker:disable-line
# ```
#
# Or as a `Criteria` hash keyed by field name, which also supports:
#
# * An `Array` value, matching any of its values via `IN`
# * A `nil` value, matching via `IS NULL`
# * The owning side of a `AORMA::ManyToOne` or `AORMA::OneToOne` association, given the identifier of the associated entity
#
# ```
# alias Criteria = AORM::EntityRepository::Criteria
#
# repository.find_by Criteria{"name" => ["George", "Jim"] of DB::Any}
# repository.find_by Criteria{"deleted_at" => nil}
# em.repository(Post).find_by Criteria{"author" => 1_i64}
# ```
#
# Build the hash with the `Criteria` alias; a plain hash literal such as `{"name" => "George"}` is a `Hash(String, String)`, which doesn't match it.
#
# `#find_by` and `#find_one_by` additionally accept an *order_by* hash mapping field names to `"ASC"` or `"DESC"`, and `#find_by` a *limit* and *offset*:
#
# ```
# repository.find_by(order_by: {"name" => "ASC"}, limit: 10, offset: 20)
# ```
#
# Anything more complex, such as joins or aggregates, goes through a native query, see `AORM::NativeQuery`.
#
# ## Custom Repositories
#
# A subclass of this type can group the queries of an entity in one place.
# Set it as the entity's *repository_class* on `AORMA::Entity`, and `AORM::EntityManager#repository` returns it in place of the default:
#
# ```
# @[AORMA::Entity(repository_class: UserRepository)]
# class User < AORM::Entity
#   # ...
# end
#
# class UserRepository < AORM::EntityRepository(User)
#   def find_by_username(username : String) : User?
#     self.find_one_by username: username
#   end
# end
#
# em.repository(User).find_by_username "George" # => #<User:0x7f3a1c2b5e40 @id=1, @name="George">
# ```
class Athena::ORM::EntityRepository(EntityType) < Athena::ORM::RepositoryInterface
  # Field names mapped to the values to filter on, see [Criteria][Athena::ORM::EntityRepository--criteria].
  alias Criteria = Hash(String, DB::Any | Array(DB::Any))

  # Returns the class of the entities this repository finds.
  getter entity_class : AORM::Entity.class

  # Returns the entity manager this repository finds entities with.
  getter em : AORM::EntityManagerInterface

  # Returns the mapping metadata of `EntityType`.
  getter class_metadata : AORM::Mapping::ClassInterface

  # :nodoc:
  def initialize(@em : AORM::EntityManagerInterface, @class_metadata : AORM::Mapping::ClassInterface)
    @entity_class = @class_metadata.entity_class
  end

  # Returns the entity with the identifier *id*, or `nil` if there isn't one.
  #
  # See `AORM::EntityManager#find`.
  def find(id : Hash(String, Int | String) | Int | String, lock_mode : AORM::LockMode = :none, lock_version : Int32? = nil) : EntityType?
    @em.find(@entity_class, id, lock_mode, lock_version).as EntityType?
  end

  # Returns the entity with the identifier *id*.
  # Raises an `AORM::Exceptions::NoResult` if there isn't one.
  #
  # See `AORM::EntityManager#find`.
  def find!(id : Hash(String, Int | String) | Int | String, lock_mode : AORM::LockMode = :none, lock_version : Int32? = nil) : EntityType
    @em.find!(@entity_class, id, lock_mode, lock_version).as EntityType
  end

  # Returns every entity of type `EntityType`.
  def find_all : Array(EntityType)
    self.find_by Criteria.new
  end

  # Returns the entities matching *criteria*, given as keyword arguments.
  #
  # ```
  # repository.find_by name: "George" # => [#<User:0x7f3a1c2b5e40 @id=1, @name="George">]
  # ```
  #
  # See [Criteria][Athena::ORM::EntityRepository--criteria].
  def find_by(**criteria : **T) : Array(EntityType) forall T
    {%
      entity_fields = EntityType.instance_vars.select(&.annotation(AORMA::Column)).map do |c|
        {name: c.name.id, type: c.type.resolve}
      end

      T.keys.each do |k|
        type = T[k]

        unless entity_field = entity_fields.find(&.["name"].==(k))
          k.raise "Unknown field '#{k}' for entity type #{EntityType}."
        end

        unless type <= entity_field["type"]
          k.raise "Expected '#{entity_field["type"]}' for field '#{k}', got '#{type}'."
        end
      end
    %}

    self.find_by self.named_criteria(criteria)
  end

  # Returns the entities matching *criteria*, ordered by *order_by*, skipping the first *offset* entities, and returning at most *limit*.
  #
  # ```
  # repository.find_by AORM::EntityRepository::Criteria{"active" => true}, {"name" => "ASC"}, limit: 10, offset: 20
  # ```
  #
  # See [Criteria][Athena::ORM::EntityRepository--criteria].
  def find_by(criteria : Criteria = Criteria.new, order_by : Hash(String, String) = Hash(String, String).new, limit : Int? = nil, offset : Int? = nil) : Array(EntityType)
    persister = @em.unit_of_work.entity_persister @entity_class

    persister.load_all(criteria, order_by, limit, offset).map &.as EntityType
  end

  # Returns the first entity matching *criteria*, given as keyword arguments, or `nil` if there isn't one.
  #
  # ```
  # repository.find_one_by name: "George" # => #<User:0x7f3a1c2b5e40 @id=1, @name="George">
  # ```
  #
  # See [Criteria][Athena::ORM::EntityRepository--criteria].
  def find_one_by(**criteria : **T) : EntityType? forall T
    {%
      entity_fields = EntityType.instance_vars.select(&.annotation(AORMA::Column)).map do |c|
        {name: c.name.id, type: c.type.resolve}
      end

      T.keys.each do |k|
        type = T[k]

        unless entity_field = entity_fields.find(&.["name"].==(k))
          k.raise "Unknown field '#{k}' for entity type #{EntityType}."
        end

        unless type <= entity_field["type"]
          k.raise "Expected '#{entity_field["type"]}' for field '#{k}', got '#{type}'."
        end
      end
    %}

    self.find_one_by self.named_criteria(criteria)
  end

  # Returns the first entity matching *criteria*, ordered by *order_by*, or `nil` if there isn't one.
  #
  # See [Criteria][Athena::ORM::EntityRepository--criteria].
  def find_one_by(criteria : Criteria, order_by : Hash(String, String) = Hash(String, String).new) : EntityType?
    persister = @em.unit_of_work.entity_persister @entity_class

    persister.load(criteria, limit: 1, order_by: order_by).as EntityType?
  end

  # Returns the number of entities of type `EntityType`.
  def count : Int
    self.count Criteria.new
  end

  # Returns the number of entities matching *criteria*, given as keyword arguments.
  #
  # ```
  # repository.count active: true # => 1
  # ```
  #
  # See [Criteria][Athena::ORM::EntityRepository--criteria].
  def count(**criteria : **T) : Int forall T
    {%
      entity_fields = EntityType.instance_vars.select(&.annotation(AORMA::Column)).map do |c|
        {name: c.name.id, type: c.type.resolve}
      end

      T.keys.each do |k|
        type = T[k]

        unless entity_field = entity_fields.find(&.["name"].==(k))
          k.raise "Unknown field '#{k}' for entity type #{EntityType}."
        end

        unless type <= entity_field["type"]
          k.raise "Expected '#{entity_field["type"]}' for field '#{k}', got '#{type}'."
        end
      end
    %}

    self.count self.named_criteria(criteria)
  end

  # Returns the number of entities matching *criteria*.
  #
  # See [Criteria][Athena::ORM::EntityRepository--criteria].
  def count(criteria : Criteria) : Int
    @em.unit_of_work.entity_persister(@entity_class).count criteria
  end

  # Builds the criteria hash for the named-argument finders.
  # Enum values are given as the integer enum fields are stored as.
  private def named_criteria(criteria : NamedTuple) : Hash
    criteria.to_h.transform_keys(&.to_s).transform_values do |value|
      value.is_a?(::Enum) ? Mapping::EnumConversion.from_enum(value) : value
    end
  end

  def inspect(io : IO) : Nil
    io << self.class
  end
end
