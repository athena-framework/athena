# Contains all the `Athena::ORM` based annotations.
# See each annotation for more information.
#
# An entity is a class inheriting from `AORM::Entity` with the `AORMA::Entity` annotation.
# The rest of the annotations describe how it maps to the database: its table, which instance variables are columns, its identifier, and its associations with other entities.
# Methods may also be annotated to run when an entity reaches a certain point in its lifecycle, such as `AORMA::PrePersist`.
module Athena::ORM::Annotations
  # Maps an instance variable to a column of the entity's table.
  # Only instance variables with this annotation, or an association annotation such as `AORMA::ManyToOne`, are persisted.
  #
  # ```
  # @[AORMA::Entity]
  # class Message < AORM::Entity
  #   @[AORMA::Column]
  #   @[AORMA::ID]
  #   @[AORMA::GeneratedValue]
  #   property! id : Int64
  #
  #   @[AORMA::Column(length: 140)]
  #   property! text : String
  #
  #   @[AORMA::Column(name: "posted_at")]
  #   property! posted : Time
  # end
  # ```
  #
  # In this example:
  #
  # * `id` maps to the `id` column using the `bigint` type
  # * `text` maps to the `text` column using the `string` type
  # * `posted` maps to the `posted_at` column using the `datetime` type
  #
  # ## Column Types
  #
  # A column's type converts values between their Crystal and database representations, see `AORM::Types::Type`.
  # When no *type* is given, it's inferred from the instance variable's Crystal type:
  #
  # | Crystal Type | Column Type  |
  # | ------------ | ------------ |
  # | `String`     | `string`     |
  # | `Bool`       | `boolean`    |
  # | `Int16`      | `smallint`   |
  # | `Int32`      | `integer`    |
  # | `Int64`      | `bigint`     |
  # | `Float32`    | `smallfloat` |
  # | `Float64`    | `float`      |
  # | `Time`       | `datetime`   |
  # | `UUID`       | `guid`       |
  # | `Bytes`      | `blob`       |
  # | `BigDecimal` | `number`     |
  # | `Enum`       | `integer`, or `bigint` if the enum's base type is wider than `Int32` |
  #
  # A nilable instance variable, such as one declared with `property!`, maps the same way as its non-nilable type.
  # Any other Crystal type requires an explicit *type*, such as the name of a custom type, otherwise an exception is raised when the entity's metadata is built.
  #
  # NOTE: `BigDecimal` is only mapped when the program defines it, i.e. it requires `"big"`.
  #
  # ## Enums
  #
  # Enum instance variables are stored as the integer value of their member, and hydrated back into the enum.
  # A database value that isn't a member of the enum raises an `ArgumentError` when it's hydrated.
  #
  # ```
  # enum PostStatus
  #   Draft
  #   Published
  # end
  #
  # @[AORMA::Entity]
  # class Post < AORM::Entity
  #   # ...
  #
  #   @[AORMA::Column]
  #   property status : PostStatus = PostStatus::Draft
  # end
  #
  # em.repository(Post).find_by status: PostStatus::Published
  # ```
  #
  # The keyword argument finders of `AORM::EntityRepository` accept enum members, as shown above.
  # Criteria given as a `Hash` need the member's integer value instead.
  #
  # TODO: Storing an enum member by its name isn't supported yet.
  #
  # ## Quoting Reserved Words
  #
  # Table and column names are used in SQL as written, without quoting them.
  # Quoting isn't automatic because it changes which table or column a name refers to on some databases; e.g. Postgres folds unquoted names to lowercase, but matches quoted names exactly.
  # If a name is a reserved word, wrap it in backticks to have it quoted, using the quoting style of the database in use:
  #
  # ```
  # @[AORMA::Column(name: "`order`")]
  # property! order : Int32
  # ```
  #
  # The same applies to the names given to `AORMA::Table`, `AORMA::JoinColumn`, `AORMA::InverseJoinColumn`, and `AORMA::JoinTable`.
  #
  # # Configuration
  #
  # ## Optional Arguments
  #
  # ### name
  #
  # **Type:** `String` **Default:** the name of the instance variable
  #
  # The name of the column.
  #
  # ---
  #
  # ### type
  #
  # **Type:** `String` **Default:** inferred from the instance variable's type
  #
  # The name of the `AORM::Types::Type` used to convert the column's values.
  # See `AORM::Types` for the names of the built-in types.
  #
  # ---
  #
  # ### insertable
  #
  # **Type:** `Bool` **Default:** `true`
  #
  # Whether the column is included in the `INSERT` statement of a new entity.
  # Values the database stores instead, such as a column default, aren't read back into the entity; use `AORM::EntityManager#refresh` to load them.
  #
  # ---
  #
  # ### updatable
  #
  # **Type:** `Bool` **Default:** `true`
  #
  # Whether the column is included in the `UPDATE` statement of a changed entity.
  #
  # ---
  #
  # ### nullable
  #
  # **Type:** `Bool` **Default:** `false`
  #
  # Whether the column allows `NULL` values.
  #
  # TODO: Only used to generate a schema, which isn't supported yet.
  # Whether an instance variable can be `nil` comes from its Crystal type.
  #
  # ---
  #
  # ### length
  #
  # **Type:** `Int32?` **Default:** `nil`
  #
  # The maximum length of a `string` column.
  # Values aren't validated against it.
  #
  # TODO: Only used to generate a schema, which isn't supported yet.
  #
  # ---
  #
  # ### precision
  #
  # **Type:** `Int32?` **Default:** `nil`
  #
  # The maximum number of digits stored by a `decimal` or `number` column.
  #
  # TODO: Only used to generate a schema, which isn't supported yet.
  #
  # ---
  #
  # ### scale
  #
  # **Type:** `Int32?` **Default:** `nil`
  #
  # The number of digits to the right of the decimal point stored by a `decimal` or `number` column.
  # It must not be greater than *precision*.
  #
  # TODO: Only used to generate a schema, which isn't supported yet.
  #
  # ---
  #
  # ### unique
  #
  # **Type:** `Bool` **Default:** `false`
  #
  # Whether the column's values must be unique across every row of the table.
  #
  # TODO: Only used to generate a schema, which isn't supported yet.
  #
  # ---
  #
  # ### index
  #
  # **Type:** `Bool` **Default:** `false`
  #
  # Whether the column is indexed.
  #
  # TODO: Only used to generate a schema, which isn't supported yet.
  #
  # ---
  #
  # ### column_definition
  #
  # **Type:** `String?` **Default:** `nil`
  #
  # The SQL declaring the column, from after its name, e.g. `"CHAR(2) NOT NULL"`.
  # It replaces the declaration derived from the column's other arguments, and isn't portable between databases.
  # The column's *type* still converts its values.
  #
  # TODO: Only used to generate a schema, which isn't supported yet.
  #
  # ---
  #
  # ### generated
  #
  # **Type:** `String?` **Default:** `nil`
  #
  # When the database generates the column's value, so that it's read back into the entity after an `INSERT` or `UPDATE`.
  #
  # TODO: Not supported yet; using it is a compile-time error.
  annotation Column; end

  # Marks an instance variable as the entity's identifier, its primary key.
  # Every entity must have an identifier, and the instance variable must also be mapped with `AORMA::Column`.
  #
  # ```
  # @[AORMA::Entity]
  # class User < AORM::Entity
  #   @[AORMA::Column]
  #   @[AORMA::ID]
  #   @[AORMA::GeneratedValue]
  #   property! id : Int64
  # end
  # ```
  #
  # Unless the database generates it, see `AORMA::GeneratedValue`, the identifier must be assigned before the entity is passed to `AORM::EntityManager#persist`.
  #
  # ## Composite Keys
  #
  # Applying the annotation to more than one instance variable defines a composite primary key.
  # Entities with one are found with a `Hash` holding a value for each identifier field:
  #
  # ```
  # @[AORMA::Entity]
  # class Translation < AORM::Entity
  #   @[AORMA::Column]
  #   @[AORMA::ID]
  #   property! article_id : Int64
  #
  #   @[AORMA::Column]
  #   @[AORMA::ID]
  #   property! language : String
  #
  #   @[AORMA::Column]
  #   property! title : String
  # end
  #
  # em.find Translation, {"article_id" => 1, "language" => "en"}
  # ```
  #
  # On databases that support `RETURNING`, the database can also generate a composite key, in which case every identifier column is read back after the `INSERT`.
  #
  # TODO: Using an association as part of the identifier isn't supported yet.
  annotation ID; end

  # Has the database generate the value of the entity's identifier.
  # Only has an effect alongside `AORMA::ID`.
  #
  # ```
  # @[AORMA::Column]
  # @[AORMA::ID]
  # @[AORMA::GeneratedValue]
  # property! id : Int64
  # ```
  #
  # The generated identifier is assigned to the entity when it's inserted, during `AORM::EntityManager#flush`.
  # It isn't available right after `AORM::EntityManager#persist`.
  #
  # # Configuration
  #
  # ## Optional Arguments
  #
  # ### strategy
  #
  # **Type:** `AORM::Mapping::GeneratedValueStrategy` **Default:** `:auto`
  #
  # How the identifier is generated:
  #
  # * `:auto` - Uses the strategy preferred by the database, which is `:identity` for every supported database.
  # * `:identity` - The database generates the value when the row is inserted, e.g. via an `AUTO_INCREMENT` or `GENERATED BY DEFAULT AS IDENTITY` column.
  # It's read back with `RETURNING` on the databases that support it, and as the last inserted ID otherwise.
  # * `:none` - Your code assigns the identifier before persisting the entity, the same as not applying this annotation.
  # * `:sequence` - The value is taken from a database sequence, see `AORMA::SequenceGenerator`.
  # * `:custom` - The value is generated by your own code.
  #
  # TODO: The `:sequence` and `:custom` strategies aren't supported yet; using them raises when the entity's metadata is built.
  annotation GeneratedValue; end

  # Configures the database sequence the `:sequence` strategy of `AORMA::GeneratedValue` takes identifiers from.
  #
  # ```
  # @[AORMA::Column]
  # @[AORMA::ID]
  # @[AORMA::GeneratedValue(strategy: :sequence)]
  # @[AORMA::SequenceGenerator(name: "message_seq", allocation_size: 100)]
  # property! id : Int64
  # ```
  #
  # TODO: Not supported yet; the annotation is ignored, and the `:sequence` strategy raises when the entity's metadata is built.
  #
  # # Configuration
  #
  # ## Required Arguments
  #
  # ### name
  #
  # **Type:** `String`
  #
  # The name of the sequence.
  #
  # ## Optional Arguments
  #
  # ### allocation_size
  #
  # **Type:** `Int64` **Default:** `1`
  #
  # How much the sequence is incremented by each time its next value is fetched.
  # Values larger than `1` allow generating identifiers for that many entities with a single query.
  annotation SequenceGenerator; end

  # Configures the table an entity is stored in.
  # Without it, the table is named after the entity's class, without its namespace, in snake case; e.g. `Blog::BlogPost` is stored in `blog_post`.
  #
  # ```
  # @[AORMA::Entity]
  # @[AORMA::Table(name: "posts")]
  # class Post < AORM::Entity
  #   # ...
  # end
  # ```
  #
  # The name may also be given as the first positional argument, e.g. `@[AORMA::Table("posts")]`.
  #
  # # Configuration
  #
  # ## Optional Arguments
  #
  # ### name
  #
  # **Type:** `String` **Default:** the class name in snake case
  #
  # The name of the table.
  # Wrap it in backticks if it needs to be quoted, see [Quoting Reserved Words][Athena::ORM::Annotations::Column--quoting-reserved-words].
  #
  # ---
  #
  # ### schema
  #
  # **Type:** `String?` **Default:** `nil`
  #
  # The name of the schema the table is in.
  # It may also be given as part of *name*, e.g. `"myschema.posts"`.
  annotation Table; end

  # Marks a class as an entity, whose instances are persisted by the ORM.
  # The class must inherit from `AORM::Entity`.
  #
  # ```
  # @[AORMA::Entity]
  # class User < AORM::Entity
  #   @[AORMA::Column]
  #   @[AORMA::ID]
  #   @[AORMA::GeneratedValue]
  #   property! id : Int64
  #
  #   @[AORMA::Column]
  #   property! name : String
  # end
  # ```
  #
  # The ORM never calls an entity's constructor, so it's free to require any arguments.
  # Entities loaded from the database are allocated with the default values of their instance variables, and then have their mapped instance variables set directly.
  # Mapped instance variables are always read and written directly, so custom logic in getters and setters doesn't apply to the values the ORM loads or persists.
  #
  # # Configuration
  #
  # ## Optional Arguments
  #
  # ### repository_class
  #
  # **Type:** `AORM::RepositoryInterface.class` **Default:** `nil`
  #
  # The repository `AORM::EntityManager#repository` returns for this entity, in place of an `AORM::EntityRepository`.
  # See [Custom Repositories][Athena::ORM::EntityRepository--custom-repositories].
  #
  # ---
  #
  # ### read_only
  #
  # **Type:** `Bool` **Default:** `false`
  #
  # Whether changes to managed instances of the entity are ignored when flushing.
  # Read-only entities can still be persisted and removed, and skipping them saves computing their changes on every flush.
  annotation Entity; end

  # Maps an instance variable to a single entity, where each entity is associated with at most one entity on the other side.
  #
  # ```
  # @[AORMA::Entity]
  # class Product < AORM::Entity
  #   # ...
  #
  #   @[AORMA::OneToOne]
  #   property shipment : Shipment? = nil
  # end
  # ```
  #
  # The target entity is inferred from the instance variable's type.
  # The entity holding the foreign key column is the owning side of the association.
  # Here that's `Product`, via a `shipment_id` column referencing the `id` of the shipment; use `AORMA::JoinColumn` to name the columns differently.
  #
  # ## Bidirectional
  #
  # Mapping the association on the target entity too allows navigating it from both sides.
  # That side, the inverse side, names the owning side's property via *mapped_by*, and the owning side names the inverse side's property via *inversed_by*:
  #
  # ```
  # @[AORMA::Entity]
  # class Customer < AORM::Entity
  #   # The inverse side.
  #   @[AORMA::OneToOne(mapped_by: "customer")]
  #   property cart : Cart? = nil
  # end
  #
  # @[AORMA::Entity]
  # class Cart < AORM::Entity
  #   # The owning side, holding the `customer_id` column.
  #   @[AORMA::OneToOne(inversed_by: "cart")]
  #   property customer : Customer? = nil
  # end
  # ```
  #
  # Only the owning side is checked for changes when flushing, see the [associations](/ORM/#associations) section of the manual.
  #
  # ## Loading
  #
  # The target of the owning side is loaded along with the entity.
  # Any target that isn't in the identity map already is loaded with its own `SELECT`.
  # Typing the instance variable as `AORM::Proxy(T)?` instead loads the target only once it's used, see `AORM::Proxy`.
  # The inverse side is always loaded along with the entity.
  #
  # # Configuration
  #
  # ## Optional Arguments
  #
  # ### mapped_by
  #
  # **Type:** `String?` **Default:** `nil`
  #
  # The name of the owning side's property on the target entity.
  # Makes this property the inverse side of the association.
  #
  # ---
  #
  # ### inversed_by
  #
  # **Type:** `String?` **Default:** `nil`
  #
  # The name of the inverse side's property on the target entity, if the association is bidirectional.
  #
  # ---
  #
  # ### cascade
  #
  # **Type:** `Array(String)?` **Default:** `nil`
  #
  # The operations on this entity that are also applied to the associated entity, see the [associations](/ORM/#cascading-operations) section of the manual.
  # One or more of `"persist"`, `"remove"`, `"detach"`, or `"all"`.
  #
  # ---
  #
  # ### orphan_removal
  #
  # **Type:** `Bool` **Default:** `false`
  #
  # Whether the associated entity is removed when it's replaced by another entity or set to `nil`.
  # On the owning side, it also implies the `"remove"` cascade.
  #
  # ---
  #
  # ### target_entity
  #
  # **Type:** `AORM::Entity.class?` **Default:** the instance variable's type
  #
  # The class of the associated entity, if it can't be inferred from the instance variable's type.
  #
  # ---
  #
  # ### fetch_mode
  #
  # **Type:** `AORM::Mapping::FetchMode` **Default:** `:lazy`
  #
  # When the associated entity is loaded.
  #
  # TODO: Not supported yet; it's ignored.
  # The owning side is loaded lazily when typed as `AORM::Proxy(T)?`, as described above.
  annotation OneToOne; end

  # Maps an instance variable to the collection of entities on the many side of a one-to-many association.
  # It's the inverse side of a `AORMA::ManyToOne` association, which holds the foreign key column.
  #
  # ```
  # @[AORMA::Entity]
  # class Product < AORM::Entity
  #   # ...
  #
  #   @[AORMA::OneToMany(mapped_by: "product")]
  #   property features : AORM::Collection(Feature) = AORM::ArrayCollection(Feature).new
  # end
  #
  # @[AORMA::Entity]
  # class Feature < AORM::Entity
  #   # ...
  #
  #   @[AORMA::ManyToOne(inversed_by: "features")]
  #   property product : Product? = nil
  # end
  # ```
  #
  # The target entity is inferred from the collection's type.
  # The collection is loaded the first time it's used, with a `SELECT` on the target's table filtered by the foreign key column.
  # Since it's the inverse side, adding or removing elements doesn't change anything in the database; set the owning `AORMA::ManyToOne` side of each element instead.
  #
  # TODO: A unidirectional one-to-many association via a join table isn't supported yet.
  # Use a `AORMA::ManyToMany` association instead.
  #
  # # Configuration
  #
  # ## Required Arguments
  #
  # ### mapped_by
  #
  # **Type:** `String`
  #
  # The name of the `AORMA::ManyToOne` property on the target entity.
  # Omitting it raises when the entity's metadata is built.
  #
  # ## Optional Arguments
  #
  # ### cascade
  #
  # **Type:** `Array(String)?` **Default:** `nil`
  #
  # The operations on this entity that are also applied to the entities in the collection, see the [associations](/ORM/#cascading-operations) section of the manual.
  # One or more of `"persist"`, `"remove"`, `"detach"`, or `"all"`.
  #
  # ---
  #
  # ### orphan_removal
  #
  # **Type:** `Bool` **Default:** `false`
  #
  # Whether entities removed from the collection are removed from the database.
  # It also implies the `"remove"` cascade.
  #
  # ---
  #
  # ### target_entity
  #
  # **Type:** `AORM::Entity.class?` **Default:** the collection's type argument
  #
  # The class of the associated entities, if it can't be inferred from the instance variable's type.
  #
  # ---
  #
  # ### fetch_mode
  #
  # **Type:** `AORM::Mapping::FetchMode` **Default:** `:lazy`
  #
  # When the collection is loaded.
  #
  # TODO: Not supported yet; it's ignored, and collections are always loaded lazily.
  #
  # ---
  #
  # ### index_by
  #
  # **Type:** `String?` **Default:** `nil`
  #
  # The field of the target entity the collection is indexed by.
  #
  # TODO: Not supported yet; it's ignored.
  annotation OneToMany; end

  # Maps an instance variable to a single entity, where many entities may be associated with the same one.
  # It's always the owning side of the association, holding the foreign key column.
  #
  # ```
  # @[AORMA::Entity]
  # class User < AORM::Entity
  #   # ...
  #
  #   @[AORMA::ManyToOne]
  #   property address : Address? = nil
  # end
  # ```
  #
  # The target entity is inferred from the instance variable's type.
  # Here the foreign key column is `address_id`, referencing the `id` of the address; use `AORMA::JoinColumn` to name the columns differently.
  # The target entity can also map the association, as a `AORMA::OneToMany` collection naming this property via *mapped_by*.
  #
  # The target is loaded along with the entity.
  # Any target that isn't in the identity map already is loaded with its own `SELECT`.
  # Typing the instance variable as `AORM::Proxy(T)?` instead loads the target only once it's used, see `AORM::Proxy`.
  #
  # # Configuration
  #
  # ## Optional Arguments
  #
  # ### inversed_by
  #
  # **Type:** `String?` **Default:** `nil`
  #
  # The name of the `AORMA::OneToMany` property on the target entity, if the association is bidirectional.
  #
  # ---
  #
  # ### cascade
  #
  # **Type:** `Array(String)?` **Default:** `nil`
  #
  # The operations on this entity that are also applied to the associated entity, see the [associations](/ORM/#cascading-operations) section of the manual.
  # One or more of `"persist"`, `"remove"`, `"detach"`, or `"all"`.
  #
  # ---
  #
  # ### target_entity
  #
  # **Type:** `AORM::Entity.class?` **Default:** the instance variable's type
  #
  # The class of the associated entity, if it can't be inferred from the instance variable's type.
  #
  # ---
  #
  # ### fetch_mode
  #
  # **Type:** `AORM::Mapping::FetchMode` **Default:** `:lazy`
  #
  # When the associated entity is loaded.
  #
  # TODO: Not supported yet; it's ignored.
  # The association is loaded lazily when typed as `AORM::Proxy(T)?`, as described above.
  annotation ManyToOne; end

  # Maps an instance variable to a collection of entities, where each entity may be associated with many entities on the other side.
  # The associations are stored as rows of a join table, holding a foreign key column to each side.
  #
  # ```
  # @[AORMA::Entity]
  # class User < AORM::Entity
  #   # ...
  #
  #   @[AORMA::ManyToMany]
  #   property groups : AORM::Collection(Group) = AORM::ArrayCollection(Group).new
  # end
  # ```
  #
  # The target entity is inferred from the collection's type.
  # Here the join table is `user_group`, with a `user_id` column referencing the `id` of the user, and a `group_id` column referencing the `id` of the group.
  # Use `AORMA::JoinTable`, `AORMA::JoinColumn`, and `AORMA::InverseJoinColumn` to name them differently.
  #
  # The collection is loaded the first time it's used.
  # Adding or removing elements inserts or deletes the corresponding join table rows when flushing.
  #
  # NOTE: When an entity is removed, its join table rows are deleted along with it, unless a join column of the owning side is declared `ON DELETE CASCADE`.
  # That's the case for default join columns, i.e. when `AORMA::JoinColumn` or `AORMA::InverseJoinColumn` is missing, and for those given `on_delete: "CASCADE"`.
  # The database is then expected to delete the rows itself.
  #
  # ## Bidirectional
  #
  # Mapping the association on the target entity too allows navigating it from both sides.
  # Either side can be the owning side, which writes the join table rows.
  # The inverse side names the owning side's property via *mapped_by*, and the owning side names the inverse side's property via *inversed_by*:
  #
  # ```
  # @[AORMA::Entity]
  # class User < AORM::Entity
  #   # The owning side.
  #   @[AORMA::ManyToMany(inversed_by: "users")]
  #   property groups : AORM::Collection(Group) = AORM::ArrayCollection(Group).new
  #
  #   def add_group(group : Group) : Nil
  #     @groups << group
  #     group.users << self
  #   end
  # end
  #
  # @[AORMA::Entity]
  # class Group < AORM::Entity
  #   # The inverse side.
  #   @[AORMA::ManyToMany(mapped_by: "groups")]
  #   property users : AORM::Collection(User) = AORM::ArrayCollection(User).new
  # end
  # ```
  #
  # Only changes to the owning side's collection are written to the join table.
  # Choose the side that's responsible for managing the association as the owning side, and keep the other side in sync, as `add_group` does above.
  #
  # # Configuration
  #
  # ## Optional Arguments
  #
  # ### mapped_by
  #
  # **Type:** `String?` **Default:** `nil`
  #
  # The name of the owning side's property on the target entity.
  # Makes this property the inverse side of the association.
  #
  # ---
  #
  # ### inversed_by
  #
  # **Type:** `String?` **Default:** `nil`
  #
  # The name of the inverse side's property on the target entity, if the association is bidirectional.
  #
  # ---
  #
  # ### cascade
  #
  # **Type:** `Array(String)?` **Default:** `nil`
  #
  # The operations on this entity that are also applied to the entities in the collection, see the [associations](/ORM/#cascading-operations) section of the manual.
  # One or more of `"persist"`, `"remove"`, `"detach"`, or `"all"`.
  #
  # ---
  #
  # ### orphan_removal
  #
  # **Type:** `Bool` **Default:** `false`
  #
  # Whether entities removed from the collection are removed from the database.
  #
  # ---
  #
  # ### target_entity
  #
  # **Type:** `AORM::Entity.class?` **Default:** the collection's type argument
  #
  # The class of the associated entities, if it can't be inferred from the instance variable's type.
  #
  # ---
  #
  # ### fetch_mode
  #
  # **Type:** `AORM::Mapping::FetchMode` **Default:** `:lazy`
  #
  # When the collection is loaded.
  #
  # TODO: Not supported yet; it's ignored, and collections are always loaded lazily.
  #
  # ---
  #
  # ### index_by
  #
  # **Type:** `String?` **Default:** `nil`
  #
  # The field of the target entity the collection is indexed by.
  #
  # TODO: Not supported yet; it's ignored.
  annotation ManyToMany; end

  # Configures the join table of the owning side of a `AORMA::ManyToMany` association.
  # Without it, the join table is named after the classes of both sides, without their namespaces, in snake case and joined by an underscore; e.g. `user_group`.
  #
  # ```
  # @[AORMA::ManyToMany]
  # @[AORMA::JoinTable(name: "users_groups")]
  # @[AORMA::JoinColumn(name: "user_id", referenced_column_name: "id")]
  # @[AORMA::InverseJoinColumn(name: "group_id", referenced_column_name: "id")]
  # property groups : AORM::Collection(Group) = AORM::ArrayCollection(Group).new
  # ```
  #
  # The join table's columns are configured with `AORMA::JoinColumn` for the columns referencing this entity, and `AORMA::InverseJoinColumn` for those referencing the target entity.
  #
  # # Configuration
  #
  # ## Optional Arguments
  #
  # ### name
  #
  # **Type:** `String?` **Default:** the class names of both sides in snake case
  #
  # The name of the join table.
  # Wrap it in backticks if it needs to be quoted, see [Quoting Reserved Words][Athena::ORM::Annotations::Column--quoting-reserved-words].
  #
  # ---
  #
  # ### schema
  #
  # **Type:** `String?` **Default:** `nil`
  #
  # The name of the schema the join table is in.
  annotation JoinTable; end

  # Marks a type as embeddable: a value object whose properties are stored as columns of the table of each entity that embeds it.
  #
  # Unlike a custom `AORM::Types::Type`, which stores a value object in a single column, an embeddable spreads it over several columns that can each be queried and indexed.
  # Unlike mapped properties shared through a module, an embeddable is its own object, and an entity can embed it more than once:
  #
  # ```
  # @[AORMA::Embeddable]
  # record Money, amount : BigDecimal, currency : String
  #
  # @[AORMA::Entity]
  # class Order < AORM::Entity
  #   # ...
  #
  #   property total : Money # Stored in the `total_amount` and `total_currency` columns
  #   property tax : Money   # Stored in the `tax_amount` and `tax_currency` columns
  # end
  # ```
  #
  # TODO: Not supported yet.
  # In the meantime, store a value object that fits in one column with a custom `AORM::Types::Type`, or map its values as separate columns of the entity.
  annotation Embeddable; end

  # Configures the foreign key column of the owning side of a `AORMA::OneToOne` or `AORMA::ManyToOne` association, or of the join table of a `AORMA::ManyToMany` association.
  #
  # ```
  # @[AORMA::ManyToOne]
  # @[AORMA::JoinColumn(name: "author_id", referenced_column_name: "id")]
  # property author : User? = nil
  # ```
  #
  # On a `AORMA::ManyToMany` association, it configures the join table column referencing this entity, while `AORMA::InverseJoinColumn` configures the one referencing the target entity.
  #
  # # Configuration
  #
  # ## Optional Arguments
  #
  # ### name
  #
  # **Type:** `String?` **Default:** see below
  #
  # The name of the foreign key column.
  # On a `AORMA::OneToOne` or `AORMA::ManyToOne` association, it defaults to the name of the property followed by `_id`.
  # On a join table, it defaults to the snake case name of this entity's class followed by `_id`.
  # Wrap it in backticks if it needs to be quoted, see [Quoting Reserved Words][Athena::ORM::Annotations::Column--quoting-reserved-words].
  #
  # ---
  #
  # ### referenced_column_name
  #
  # **Type:** `String?` **Default:** `"id"`
  #
  # The name of the column the foreign key references.
  #
  # ---
  #
  # ### nullable
  #
  # **Type:** `Bool?` **Default:** `true`
  #
  # Whether the association may be empty, i.e. its column `NULL`.
  # When flushing entities that reference each other in a cycle, a nullable column allows inserting them with `NULL` first and setting the column afterwards.
  # Join table columns are never nullable.
  #
  # ---
  #
  # ### unique
  #
  # **Type:** `Bool` **Default:** `false`
  #
  # Whether the column's values must be unique.
  #
  # TODO: Only used to generate a schema, which isn't supported yet; it's ignored.
  #
  # ---
  #
  # ### deferrable
  #
  # **Type:** `Bool` **Default:** `false`
  #
  # Whether the foreign key constraint can be deferred until the end of the transaction.
  #
  # TODO: Only used to generate a schema, which isn't supported yet; it's ignored.
  #
  # ---
  #
  # ### on_delete
  #
  # **Type:** `String?` **Default:** `nil`
  #
  # The `ON DELETE` action of the foreign key constraint, e.g. `"CASCADE"` or `"SET NULL"`.
  # On a `AORMA::ManyToMany` association, `"CASCADE"` tells the ORM that the database deletes the join table rows of a removed entity, so it doesn't delete them itself.
  #
  # TODO: Otherwise only used to generate a schema, which isn't supported yet.
  #
  # ---
  #
  # ### column_definition
  #
  # **Type:** `String?` **Default:** `nil`
  #
  # The SQL declaring the column, from after its name.
  #
  # TODO: Only used to generate a schema, which isn't supported yet; it's ignored.
  annotation JoinColumn; end

  # Configures the column of a `AORMA::ManyToMany` association's join table that references the target entity.
  # Without it, the column is named after the target entity's class in snake case followed by `_id`, and references its `id` column.
  #
  # ```
  # @[AORMA::ManyToMany]
  # @[AORMA::JoinTable(name: "users_groups")]
  # @[AORMA::JoinColumn(name: "user_id", referenced_column_name: "id")]
  # @[AORMA::InverseJoinColumn(name: "group_id", referenced_column_name: "id")]
  # property groups : AORM::Collection(Group) = AORM::ArrayCollection(Group).new
  # ```
  #
  # See `AORMA::JoinColumn` for the column referencing this entity.
  #
  # # Configuration
  #
  # ## Optional Arguments
  #
  # ### name
  #
  # **Type:** `String?` **Default:** the target entity's class name in snake case followed by `_id`
  #
  # The name of the join table column.
  # Wrap it in backticks if it needs to be quoted, see [Quoting Reserved Words][Athena::ORM::Annotations::Column--quoting-reserved-words].
  #
  # ---
  #
  # ### referenced_column_name
  #
  # **Type:** `String?` **Default:** `"id"`
  #
  # The name of the target entity's column the join table column references.
  #
  # ---
  #
  # ### on_delete
  #
  # **Type:** `String?` **Default:** `nil`
  #
  # The `ON DELETE` action of the foreign key constraint, the same as on `AORMA::JoinColumn`.
  #
  # ---
  #
  # ### unique, deferrable, column_definition
  #
  # The same as on `AORMA::JoinColumn`.
  #
  # TODO: Only used to generate a schema, which isn't supported yet; they're ignored.
  annotation InverseJoinColumn; end

  # Marks a method to be called after the entity is loaded from the database or refreshed.
  #
  # TODO: Not supported yet; applying it is a compile-time error.
  annotation PostLoad; end

  # Marks a method to be called after the entity is inserted, during `AORM::EntityManager#flush`.
  # Database generated identifiers are available by then.
  #
  # ```
  # @[AORMA::PostPersist]
  # def send_welcome_email(event : AORM::Events::PostPersistEventArgs(User)) : Nil
  #   # ...
  # end
  # ```
  #
  # See `AORMA::PrePersist` for the rules every lifecycle callback follows.
  # Changes to the entity made by the callback aren't written by the current flush.
  annotation PostPersist; end

  # Marks a method to be called after the entity is deleted, during `AORM::EntityManager#flush`.
  #
  # ```
  # @[AORMA::PostRemove]
  # def delete_avatar_file(event : AORM::Events::PostRemoveEventArgs(User)) : Nil
  #   # ...
  # end
  # ```
  #
  # See `AORMA::PrePersist` for the rules every lifecycle callback follows.
  annotation PostRemove; end

  # Marks a method to be called after the entity is updated, during `AORM::EntityManager#flush`.
  #
  # ```
  # @[AORMA::PostUpdate]
  # def clear_cache(event : AORM::Events::PostUpdateEventArgs(User)) : Nil
  #   # ...
  # end
  # ```
  #
  # See `AORMA::PrePersist` for the rules every lifecycle callback follows.
  # Changes to the entity made by the callback aren't written by the current flush.
  annotation PostUpdate; end

  # Marks a method to be called at the start of every `AORM::EntityManager#flush`, for each managed entity, before its changes are computed.
  # Changes made by the callback are included in the flush.
  #
  # ```
  # @[AORMA::PreFlush]
  # def normalize_email(event : AORM::Events::PreFlushEventArgs) : Nil
  #   @email = @email.downcase
  # end
  # ```
  #
  # See `AORMA::PrePersist` for the rules every lifecycle callback follows.
  # Unlike the other callbacks, the parameter is an `AORM::Events::PreFlushEventArgs`, which isn't generic.
  annotation PreFlush; end

  # Marks a method to be called when a new entity is persisted, before it's inserted.
  # It runs once per entity, whether it's persisted via `AORM::EntityManager#persist`, a `"persist"` cascade, or found through such a cascade when flushing.
  #
  # ```
  # @[AORMA::Entity]
  # class User < AORM::Entity
  #   # ...
  #
  #   @[AORMA::Column]
  #   property! created_at : Time
  #
  #   @[AORMA::PrePersist]
  #   def set_created_at : Nil
  #     @created_at = Time.utc
  #   end
  # end
  # ```
  #
  # ## Lifecycle Callbacks
  #
  # Lifecycle callbacks are public instance methods of the entity, annotated with the event they run for.
  # They're best used for simple operations specific to the entity, such as setting timestamps.
  #
  # A callback either has no parameters, or one parameter restricted to the event's type, which gives access to the entity manager:
  #
  # ```
  # @[AORMA::PrePersist]
  # def set_created_at(event : AORM::Events::PrePersistEventArgs(User)) : Nil
  #   event.entity_manager # => AORM::EntityManager
  # end
  # ```
  #
  # Any other signature is a compile-time error.
  # An entity may have more than one callback for the same event, and a method may have more than one callback annotation.
  #
  # Callbacks declared in a module, or in an abstract parent class, apply to every entity that includes or inherits from it, see [Sharing Mapped Properties][Athena::ORM::Entity--sharing-mapped-properties].
  # Overriding such a method in the entity without the annotation removes the callback.
  #
  # NOTE: Callbacks only run for the entity they're declared on.
  # Listening to an event for every entity isn't supported yet.
  annotation PrePersist; end

  # Marks a method to be called when the entity is passed to `AORM::EntityManager#remove`, or removed by a `"remove"` cascade.
  #
  # ```
  # @[AORMA::PreRemove]
  # def detach_files(event : AORM::Events::PreRemoveEventArgs(User)) : Nil
  #   # ...
  # end
  # ```
  #
  # See `AORMA::PrePersist` for the rules every lifecycle callback follows.
  annotation PreRemove; end

  # Marks a method to be called right before a changed entity is updated, during `AORM::EntityManager#flush`.
  # It doesn't run for entities without changes.
  #
  # ```
  # @[AORMA::Entity]
  # class Post < AORM::Entity
  #   # ...
  #
  #   @[AORMA::Column]
  #   property! updated_at : Time
  #
  #   @[AORMA::PreUpdate]
  #   def set_updated_at : Nil
  #     @updated_at = Time.utc
  #   end
  # end
  # ```
  #
  # Changes made by the callback to the entity's columns are written by the same `UPDATE`.
  # Changes to its collections are not.
  #
  # See `AORMA::PrePersist` for the rules every lifecycle callback follows.
  annotation PreUpdate; end
end
