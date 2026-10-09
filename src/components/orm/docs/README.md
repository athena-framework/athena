Applications generally deal with objects, while relational databases deal with rows in tables.
Translating between the two by hand means writing the same `SELECT`/`INSERT`/`UPDATE` statements, and the code mapping their results to objects, for every type.

The `Athena::ORM` component is an object-relational mapper (ORM) that takes care of that translation.
Classes are mapped to tables with annotations, and their instances, called entities, are then persisted and loaded through an [AORM::EntityManager](/ORM/EntityManager/) without writing any SQL.
Associations between entities are references to other objects, which the ORM translates to and from foreign keys.

The ORM implements the [Data Mapper](https://martinfowler.com/eaaCatalog/dataMapper.html) pattern, so entities are plain objects that know nothing about the database.
Changes are tracked by a [Unit of Work](https://martinfowler.com/eaaCatalog/unitOfWork.html) and written in a single transaction when flushed, while an [Identity Map](https://martinfowler.com/eaaCatalog/identityMap.html) ensures each row is only ever represented by one object.

## Installation

First, install the component by adding the following to your `shard.yml`, along with the driver shard of your database, then running `shards install`:

```yaml
dependencies:
  athena-orm:
    github: athena-framework/orm
    version: ~> 0.1.0
  pg: # Or the driver of your database, see below.
    github: will/crystal-pg
    # version: ~> 0.31.0 Be sure to use the latest version!
```

Then require both, in any order:

```crystal
require "athena-orm"
require "pg"
```

### Supported Databases

| Database   | Driver Shard                                                           | Platform                                              |
| ---------- | ---------------------------------------------------------------------- | ----------------------------------------------------- |
| PostgreSQL | [will/crystal-pg](https://github.com/will/crystal-pg)                  | [AORM::Platforms::Postgres](/ORM/Platforms/Postgres/) |
| MySQL      | [crystal-lang/crystal-mysql](https://github.com/crystal-lang/crystal-mysql) | [AORM::Platforms::MySQL](/ORM/Platforms/MySQL/)  |
| MariaDB    | [crystal-lang/crystal-mysql](https://github.com/crystal-lang/crystal-mysql) | [AORM::Platforms::Maria](/ORM/Platforms/Maria/)  |
| SQLite     | [crystal-lang/crystal-sqlite3](https://github.com/crystal-lang/crystal-sqlite3) | [AORM::Platforms::SQLite](/ORM/Platforms/SQLite/) |

The platform is picked automatically from the connection's driver shard, and for MySQL and MariaDB from the server it reports, see [AORM::DriverManager](/ORM/DriverManager/).

## Usage

### Defining Entities

An entity is a class inheriting from [AORM::Entity](/ORM/Entity/) with the [AORMA::Entity](/ORM/Annotations/Entity/) annotation.
Its instance variables are mapped to columns with [AORMA::Column](/ORM/Annotations/Column/), one of which is the identifier, marked with [AORMA::ID](/ORM/Annotations/ID/):

```crystal
@[AORMA::Entity]
@[AORMA::Table(name: "users")]
class User < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int64

  @[AORMA::Column]
  property! name : String

  @[AORMA::Column]
  property? active : Bool = true
end
```

The column types are inferred from the Crystal types of the instance variables, see [AORMA::Column](/ORM/Annotations/Column/) for how, and how to configure each column.
[AORMA::GeneratedValue](/ORM/Annotations/GeneratedValue/) has the database generate the identifier when the row is inserted, such as via an `AUTO_INCREMENT` column.

NOTE: The ORM doesn't create or migrate tables; they must already exist in the database.

### Obtaining an Entity Manager

An [AORM::EntityManager](/ORM/EntityManager/) is the entry point to working with entities.
It tracks the entities of one unit of work, such as a request or a job, and isn't safe to share between fibers.
Create an [AORM::EntityManagerFactory](/ORM/EntityManagerFactory/) once, and use it to get an entity manager for each unit of work:

```crystal
ORM = AORM::EntityManagerFactory.new DB.open "postgres://user:password@localhost/blog"

ORM.with_entity_manager do |em|
  # ...
end
```

Each entity manager uses its own connection from the database's pool, which goes back to the pool once the block returns.

TIP: Within the [Athena Framework](/Framework/), configure the database URL via the [orm](/Framework/Bundle/Schema/ORM/) key instead, and inject an `AORM::EntityManagerInterface`.
Each request gets its own entity manager, whose connection goes back to the pool once the request is done.

### Persisting Entities

New entities are passed to `#persist`, then written to the database by `#flush`:

```crystal
user = User.new
user.name = "George"

em.persist user
em.flush

user.id # => 1
```

Only `#flush` writes to the database, executing every pending change in a single transaction.
Changes to entities the entity manager already manages, such as those it loaded, are detected automatically:

```crystal
user = em.find! User, 1
user.name = "Jim"

em.flush # => UPDATE users SET name = ? WHERE id = ?
```

Entities are deleted by passing them to `#remove`, followed by a flush:

```crystal
em.remove user
em.flush
```

See [AORM::EntityManager](/ORM/EntityManager/) for the details of each operation, and how to group more work in a transaction.

### Finding Entities

The simplest way to find an entity is by its identifier:

```crystal
em.find User, 1  # => #<User:0x7f3a1c2b5e40 @id=1, @name="Jim", @active=true>
em.find User, 99 # => nil
em.find! User, 99 # => raises AORM::Exceptions::NoResult
```

The [AORM::EntityRepository](/ORM/EntityRepository/) of each entity finds entities by simple conditions:

```crystal
repository = em.repository User

repository.find_by active: true
repository.find_by AORM::EntityRepository::Criteria{"name" => ["George", "Jim"] of DB::Any}, order_by: {"name" => "ASC"}, limit: 10
repository.find_one_by name: "George"
repository.count active: true
```

Anything more complex is written as SQL, with an [AORM::NativeQuery](/ORM/NativeQuery/) hydrating the results into entities.

Whichever way an entity is found, an entity manager returns the same instance for the same row:

```crystal
em.find(User, 1).same? em.repository(User).find_one_by(name: "Jim") # => true
```

### Associations

Associations between entities are mapped as instance variables referencing the associated entity, or a collection of them, using one of four annotations:

* [AORMA::ManyToOne](/ORM/Annotations/ManyToOne/) - many entities reference one entity, e.g. many posts have one author
* [AORMA::OneToMany](/ORM/Annotations/OneToMany/) - one entity has a collection of many entities, e.g. one user has many posts
* [AORMA::OneToOne](/ORM/Annotations/OneToOne/) - one entity references one entity, e.g. one user has one avatar
* [AORMA::ManyToMany](/ORM/Annotations/ManyToMany/) - entities have collections of each other, e.g. users belong to many groups, which have many users

```crystal
@[AORMA::Entity]
@[AORMA::Table(name: "posts")]
class Post < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int64

  @[AORMA::Column]
  property! title : String

  # Stored in the `author_id` column.
  @[AORMA::ManyToOne(inversed_by: "posts")]
  property author : User? = nil
end

@[AORMA::Entity]
@[AORMA::Table(name: "users")]
class User < AORM::Entity
  # ...

  @[AORMA::OneToMany(mapped_by: "author", cascade: ["persist"])]
  property posts : AORM::Collection(Post) = AORM::ArrayCollection(Post).new

  def add_post(post : Post) : Nil
    @posts << post
    post.author = self
  end
end

user = em.find! User, 1

post = Post.new
post.title = "Hello World"
user.add_post post

em.flush # => INSERT INTO posts (title, author_id) VALUES (?, ?)

user.posts.size # => 1
```

The associated entity is inferred from the type of the instance variable.
Collections are typed as [AORM::Collection](/ORM/Collection/) and initialized with an empty [AORM::ArrayCollection](/ORM/ArrayCollection/), which the ORM replaces with a lazily loaded [AORM::PersistentCollection](/ORM/PersistentCollection/).

#### Owning and Inverse Sides

An association mapped on both of its entities is bidirectional: each side is an instance variable that may change independently of the other, even though both represent the same association.
Only one of them, the owning side, is used to decide what to write to the database:

* [AORMA::ManyToOne](/ORM/Annotations/ManyToOne/) is always the owning side, holding the foreign key column
* [AORMA::OneToMany](/ORM/Annotations/OneToMany/) is always the inverse side, naming the owning side's property via `mapped_by`
* For [AORMA::OneToOne](/ORM/Annotations/OneToOne/), the owning side is the entity whose table holds the foreign key column
* For [AORMA::ManyToMany](/ORM/Annotations/ManyToMany/), either side may be the owning side; the other names it via `mapped_by`

The owning side names the inverse side's property via `inversed_by`.
Changes made only to the inverse side are ignored when flushing, so keep both sides in sync, as `User#add_post` does above.

#### Cascading Operations

By default, operations such as `#persist` only apply to the entity they're given.
The `cascade` argument of an association annotation also applies them to the associated entities:

* `"persist"` - Persisting the entity also persists its associated entities, including new entities associated with it by the time it's flushed.
* `"remove"` - Removing the entity also removes its associated entities.
* `"detach"` - Detaching the entity also detaches its associated entities.
* `"all"` - All of the above.

Without a `"persist"` cascade, a flush raises if it finds a new entity through an association, since the new entity was never persisted.
Either persist it explicitly, or cascade the operation.

Cascading `"remove"` loads every associated entity to remove it one by one, which can be costly for large collections.
A foreign key declared with `ON DELETE CASCADE` has the database delete the associated rows instead, but bypasses lifecycle callbacks and doesn't update entities already loaded into memory.

With `orphan_removal: true`, an entity removed from a [AORMA::OneToMany](/ORM/Annotations/OneToMany/) or [AORMA::ManyToMany](/ORM/Annotations/ManyToMany/) collection is removed from the database too, as is the entity of a [AORMA::OneToOne](/ORM/Annotations/OneToOne/) association once it's replaced by another entity or set to `nil`.

#### Loading Associations

Collections are loaded lazily, with a single query the first time they're used.

The entities referenced by [AORMA::ManyToOne](/ORM/Annotations/ManyToOne/) and [AORMA::OneToOne](/ORM/Annotations/OneToOne/) associations are loaded along with the entity referencing them, unless they're already in the identity map.
Typing the instance variable as `AORM::Proxy(T)?` loads it lazily instead, see [AORM::Proxy](/ORM/Proxy/).

### Lifecycle Callbacks

Methods of an entity annotated with a lifecycle event run when the entity reaches that point of its lifecycle:

```crystal
@[AORMA::Entity]
class Post < AORM::Entity
  # ...

  @[AORMA::Column]
  property! created_at : Time

  @[AORMA::Column]
  property! updated_at : Time

  @[AORMA::PrePersist]
  def set_created_at : Nil
    @created_at = @updated_at = Time.utc
  end

  @[AORMA::PreUpdate]
  def set_updated_at : Nil
    @updated_at = Time.utc
  end
end
```

Mapped properties and callbacks can be shared between entities through a module or an abstract parent class, see [AORM::Entity](/ORM/Entity/).
See [AORMA::PrePersist](/ORM/Annotations/PrePersist/) for the rules callbacks follow, and [AORM::Events::EventArgs](/ORM/Events/EventArgs/) for every event, including those dispatched to an event dispatcher on each flush.

## Learn More

* Working with entities in an [AORM::EntityManager](/ORM/EntityManager/), and transactions
* Every [annotation](/ORM/Annotations/) and its options
* Lazy loading with [AORM::Proxy](/ORM/Proxy/) and [AORM::PersistentCollection](/ORM/PersistentCollection/)
* Querying with [native SQL](/ORM/NativeQuery/)
* Custom [types](/ORM/Types/Type/) for value objects
* Listening to [events](/ORM/Events/EventArgs/)
