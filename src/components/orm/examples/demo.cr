require "pg"
require "mysql"
require "sqlite3"
require "../src/athena-orm"

# ============================================================================
# Athena::ORM end-to-end demo
# ============================================================================
#
# This file is both a smoke test for the ORM and a guided tour of how it's
# meant to be used. Run it with `crystal run examples/demo.cr` against the
# docker-compose databases (DROP+CREATE at the top makes it idempotent).
#
# This file is both a smoke test for the ORM and a guided tour of how it's meant to be used.
# Run it with `crystal run examples/demo.cr` against the docker-compose databases (DROP+CREATE at the top makes it idempotent).
#
# A few core concepts worth keeping in mind as you read the steps:
#
# * **Entity** — a Crystal class that maps to a database table. Annotated with `@[AORMA::Entity]` and optionally `@[AORMA::Table]`.
#                Columns and relationships are declared as annotated `property` declarations.
#
# * **EntityManager (EM)** — your handle on the ORM for a given connection.
#   You call `em.persist`, `em.find`, `em.flush`, etc. on it. Internally it owns a `UnitOfWork` and an identity map.
#
# * **Unit of Work** — pending writes (inserts, updates, deletes) are buffered and only sent to the DB on `em.flush`.
#                      The flush wraps everything in a single transaction and figures out the right order to write things in (so a child row's FK target is inserted before the child).
#
# * **Identity map** — once an entity is loaded, the EM remembers it by primary key.
#                      A second `em.find!(User, 1)` returns the *same* in-memory object as the first call, no extra query, until you `em.clear`.
#
# * **Change tracking** — modify a property on a managed entity, call `em.flush`, and the ORM diffs against what it loaded and emits an UPDATE for just the changed columns.
#
# * **Lazy loading** — when you load a `User`, its `groups` collection isn't populated yet; the join SELECT only fires the first time you actually touch the collection (`.size`, `.each`, `[0]`, etc.).
#
# * **Cascade** — `cascade: ["persist"]` on an association tells the ORM to `persist` related entities automatically when you persist the parent.
#                 So `em.persist(user)` followed by `em.flush` will INSERT the user *and* any associated avatar/groups in one transaction.
::Log.setup do |c|
  backend = ::Log::IOBackend.new(STDOUT, formatter: ::Log::Formatter.new { |entry, io|
    next unless entry.source == "db"
    next unless entry.severity.debug?

    query = entry.data[:query]?
    args = entry.data[:args]?

    io << "    SQL : " << (query.try(&.as_s) || entry.message)
    if args
      io << "\tARGS: " << args
    end
  }, dispatcher: :sync)
  c.bind "db.*", :debug, backend
end

# ===== Schema =====
# Four relationship shapes get exercised:
#   - scalar columns          (User.username, Group.name, Avatar.url)
#   - OneToOne owning side    (User.avatar  -> avatars.id via users.avatar_id FK)
#   - ManyToMany              (User <-> Group via user_group join table)
#   - OneToMany / ManyToOne   (User has many Posts; Post belongs to User via posts.user_id FK)
# MySQL and MariaDB share a schema.
MYSQL_SCHEMA = [
  "DROP TABLE IF EXISTS user_group",
  "DROP TABLE IF EXISTS posts",
  "DROP TABLE IF EXISTS users",
  "DROP TABLE IF EXISTS `groups`",
  "DROP TABLE IF EXISTS avatars",
  "CREATE TABLE avatars (id BIGINT AUTO_INCREMENT PRIMARY KEY, url VARCHAR(200) NOT NULL)",
  <<-SQL,
    CREATE TABLE users (
      id        BIGINT AUTO_INCREMENT PRIMARY KEY,
      username  VARCHAR(50) NOT NULL,
      active    BOOLEAN     NOT NULL DEFAULT TRUE,
      avatar_id BIGINT,
      CONSTRAINT fk_users_avatar FOREIGN KEY (avatar_id) REFERENCES avatars(id) ON DELETE SET NULL
    )
  SQL
  "CREATE TABLE `groups` (id BIGINT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(50) NOT NULL)",
  <<-SQL,
    CREATE TABLE user_group (
      user_id  BIGINT NOT NULL,
      group_id BIGINT NOT NULL,
      PRIMARY KEY (user_id, group_id),
      CONSTRAINT fk_user_group_user  FOREIGN KEY (user_id)  REFERENCES users(id)    ON DELETE CASCADE,
      CONSTRAINT fk_user_group_group FOREIGN KEY (group_id) REFERENCES `groups`(id) ON DELETE CASCADE
    )
  SQL
  <<-SQL,
    CREATE TABLE posts (
      id         BIGINT AUTO_INCREMENT PRIMARY KEY,
      title      VARCHAR(200) NOT NULL,
      status     INTEGER      NOT NULL DEFAULT 0,
      created_at DATETIME(6)  NOT NULL,
      updated_at DATETIME(6)  NOT NULL,
      user_id    BIGINT       NOT NULL,
      CONSTRAINT fk_posts_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  SQL
]

DATABASES = {
  "postgres" => {
    connection_string: "postgres://blog_user:mYAw3s0meB!og@localhost:5435/postgres",
    schema:            [
      "DROP TABLE IF EXISTS user_group CASCADE",
      "DROP TABLE IF EXISTS posts CASCADE",
      "DROP TABLE IF EXISTS users CASCADE",
      "DROP TABLE IF EXISTS groups CASCADE",
      "DROP TABLE IF EXISTS avatars CASCADE",
      "CREATE TABLE avatars (id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY, url VARCHAR(200) NOT NULL)",
      <<-SQL,
    CREATE TABLE users (
      id        BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
      username  VARCHAR(50) NOT NULL,
      active    BOOLEAN     NOT NULL DEFAULT true,
      avatar_id BIGINT REFERENCES avatars(id) ON DELETE SET NULL
    )
  SQL
      "CREATE TABLE groups (id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY, name VARCHAR(50) NOT NULL)",
      <<-SQL,
    CREATE TABLE user_group (
      user_id  BIGINT NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
      group_id BIGINT NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
      PRIMARY KEY (user_id, group_id)
    )
  SQL
      <<-SQL,
    CREATE TABLE posts (
      id         BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
      title      VARCHAR(200) NOT NULL,
      status     INTEGER      NOT NULL DEFAULT 0,
      created_at TIMESTAMP    NOT NULL,
      updated_at TIMESTAMP    NOT NULL,
      user_id    BIGINT       NOT NULL REFERENCES users(id) ON DELETE CASCADE
    )
  SQL
    ],
  },
  "mariadb" => {
    connection_string: "mysql://blog_user:mYAw3s0meB!og@localhost:3306/mariadb?ssl-mode=disabled",
    schema:            MYSQL_SCHEMA,
  },
  "mysql" => {
    connection_string: "mysql://blog_user:mYAw3s0meB!og@localhost:3307/blog?ssl-mode=disabled",
    schema:            MYSQL_SCHEMA,
  },
  "sqlite" => {
    connection_string: "sqlite3::memory:",
    schema:            [
      "PRAGMA foreign_keys = ON",
      "DROP TABLE IF EXISTS user_group",
      "DROP TABLE IF EXISTS posts",
      "DROP TABLE IF EXISTS users",
      "DROP TABLE IF EXISTS groups",
      "DROP TABLE IF EXISTS avatars",

      "CREATE TABLE avatars (id INTEGER PRIMARY KEY AUTOINCREMENT, url VARCHAR(200) NOT NULL)",
      <<-SQL,
        CREATE TABLE users (
          id        INTEGER PRIMARY KEY AUTOINCREMENT,
          username  VARCHAR(50) NOT NULL,
          active    BOOLEAN     NOT NULL DEFAULT TRUE,
          avatar_id INTEGER REFERENCES avatars(id) ON DELETE SET NULL
        )
      SQL
      "CREATE TABLE groups (id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(50) NOT NULL)",
      <<-SQL,
        CREATE TABLE user_group (
          user_id  INTEGER NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
          group_id INTEGER NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
          PRIMARY KEY (user_id, group_id)
        )
      SQL
      <<-SQL,
        CREATE TABLE posts (
          id         INTEGER PRIMARY KEY AUTOINCREMENT,
          title      VARCHAR(200) NOT NULL,
          status     INTEGER      NOT NULL DEFAULT 0,
          created_at DATETIME     NOT NULL,
          updated_at DATETIME     NOT NULL,
          user_id    INTEGER      NOT NULL REFERENCES users(id) ON DELETE CASCADE
        )
      SQL
    ],
  },
}

# ===== Entities =====
#
# Each entity is a regular Crystal class extending `AORM::Entity`.
# Annotations tell the ORM how to map it to a row:
#
#   @[AORMA::Entity]              — required marker
#   @[AORMA::Table(name: ...)]    — table name (optional, defaults derive from class)
#   @[AORMA::Column]              — map a property to a scalar column
#   @[AORMA::ID]                  — primary-key field
#   @[AORMA::GeneratedValue]      — let the DB generate the id (SERIAL/IDENTITY)
#   @[AORMA::OneToOne]            — single-record association (FK on this side)
#   @[AORMA::ManyToOne]           — single-record association (FK on this side, "many" side)
#   @[AORMA::OneToMany]           — collection-of-records association, inverse of a ManyToOne
#   @[AORMA::ManyToMany]          — collection-of-records association (join table)
#
# `target_entity` on the relationship annotations is *inferred* from the property's type restriction: `Avatar?` for OneToOne, `Collection(Group)` for ManyToMany — there's no need to repeat the type as an annotation arg.

@[AORMA::Entity]
@[AORMA::Table(name: "avatars")]
class Avatar < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int64

  @[AORMA::Column(length: 200)]
  property! url : String
end

@[AORMA::Entity(repository_class: UserRepository)]
@[AORMA::Table(name: "users")]
class User < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int64

  @[AORMA::Column(length: 50)]
  property! username : String

  @[AORMA::Column]
  property? active : Bool = true

  # OneToOne, owning side: this entity holds the FK column (`avatar_id`).
  # `cascade: ["persist"]` means persisting a User also persists its Avatar.
  #
  # `AORM::Proxy(Avatar)?` opts the field into lazy loading: a proxy instance is set when fetching a user instead of executing another query for their avatar eagerly.
  # A query is made transparently behind the scenes when a non-id avatar field accessed.
  #
  # Raw entity assignment requires an explicit wrap: `bob.avatar = AORM::Proxy.wrap(avatar)`.
  #
  # Plain `Avatar?` would keep eager loading.
  @[AORMA::OneToOne(cascade: ["persist"])]
  property avatar : AORM::Proxy(Avatar)? = nil

  # ManyToMany, owning side: writes to the join table happen from here.
  # `inversed_by` names the property on the inverse side (Group#users).
  @[AORMA::ManyToMany(inversed_by: "users", cascade: ["persist"])]
  property groups : AORM::Collection(Group) = AORM::ArrayCollection(Group).new

  # OneToMany, *inverse* side: owns no FK column; the FK lives on Post.user_id.
  # `mapped_by` names the property on the owning side (Post#user).
  @[AORMA::OneToMany(mapped_by: "user", cascade: ["persist"])]
  property posts : AORM::Collection(Post) = AORM::ArrayCollection(Post).new

  def add_group(group : Group) : Nil
    self.groups << group
    group.add_user self
  end

  def add_post(post : Post) : Nil
    self.posts << post
    post.user = self
  end
end

# Custom repository for User. Subclasses of `AORM::EntityRepository(T)` are wired to an entity via `@[AORMA::Entity(repository_class: ...)]`; once that's set, `em.repository(User)` returns this type, so callers get the extra finders without casting.
# Use cases: typed wrappers around the generic finders (`find_by_username`), or encapsulating multi-table / native SQL behind a domain method (`find_by_avatar_url`) so callers don't have to know about RSMs and join columns.
class UserRepository < AORM::EntityRepository(User)
  def find_by_username(username : String) : User?
    # named argument versions will validate that keys exist on the related entity, and the value is compatible with that field type.
    self.find_one_by username: username
  end

  def find_by_avatar_url(url : String) : Array(User)
    # TODO: Make this simpler
    rsm = AORM::Query::ResultSetMapping.new
    rsm.add_entity_result(User, "u")
    rsm.add_field_result("u", "id", "id")
    rsm.add_field_result("u", "username", "username")

    query = @em.create_native_query(<<-SQL, rsm)
      SELECT u.id, u.username
      FROM users u
      JOIN avatars a ON a.id = u.avatar_id
      WHERE a.url = ?
    SQL
    query.set_parameter(1, url)

    query.get_result.map &.as(User)
  end
end

# Mapped properties and lifecycle callbacks declared in a module apply to every entity that includes it.
# This is how to share fields, such as timestamps, between entities.
module Timestampable
  @[AORMA::Column]
  property! created_at : Time

  @[AORMA::Column]
  property! updated_at : Time

  @[AORMA::PrePersist]
  def set_created_at : Nil
    @created_at = @updated_at = Time.utc
  end

  # Fields a `PreUpdate` callback changes are written by the same UPDATE.
  @[AORMA::PreUpdate]
  def set_updated_at : Nil
    @updated_at = Time.utc
  end
end

enum PostStatus
  Draft
  Published
end

@[AORMA::Entity]
@[AORMA::Table(name: "posts")]
class Post < AORM::Entity
  include Timestampable

  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int64

  @[AORMA::Column(length: 200)]
  property! title : String

  # Enum fields are stored as the member's integer value.
  @[AORMA::Column]
  property status : PostStatus = PostStatus::Draft

  # ManyToOne, owning side: holds the FK column.
  # We declare the column name explicitly via @[AORMA::JoinColumn] for visibility (the default naming strategy would produce the same `user_id` here).
  # `inversed_by` names the property on the inverse side (User#posts).
  @[AORMA::ManyToOne(inversed_by: "posts")]
  @[AORMA::JoinColumn(name: "user_id", referenced_column_name: "id")]
  property user : User? = nil
end

# `groups` is a reserved word in MySQL, so the name has to be quoted.
# Wrapping a name in backticks marks it as quoted on every platform, which then applies its own quoting: `` `groups` `` on MySQL/MariaDB, `"groups"` on Postgres and SQLite.
# Names aren't quoted automatically because quoting can change which table a name refers to, e.g. Postgres lowercases unquoted names but matches quoted ones exactly.
@[AORMA::Entity]
@[AORMA::Table(name: "`groups`")]
class Group < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int64

  @[AORMA::Column(length: 50)]
  property! name : String

  # ManyToMany, *inverse* side: `mapped_by` points back at the owning side (User#groups).
  # The inverse side is read-only as far as the join table is concerned — modifications must go through the owning side to be persisted.
  @[AORMA::ManyToMany(mapped_by: "groups")]
  property users : AORM::Collection(User) = AORM::ArrayCollection(User).new

  def add_user(user : User) : Nil
    self.users << user
  end
end

# ===== Helpers =====

def step(n : Int32, title : String, &) : Nil
  puts
  puts "==> Step #{n}: #{title}"
  yield

  puts
end

def show(label : String, value) : Nil
  puts "    #{label.ljust(30)} => #{value.inspect}"
end

def expect(label : String, &) : Nil
  raise "FAIL: #{label}" unless yield
  puts "    ✓ #{label}"
end

# ===== Run =====

DATABASES.each do |name, config|
  puts "Running: #{name}"

  DB.open config[:connection_string] do |db|
    db.using_connection do |conn|
      config[:schema].each { |stmt| conn.exec stmt }

      em = AORM::EntityManager.new conn

      # ---------------------------------------------------------------------
      # `persist` registers the entity with the UoW; nothing hits the DB until `flush`.
      # After flush, identity-strategy id columns are populated on the in-memory entity from the row the DB just inserted (`RETURNING`, or the id MySQL reports for the INSERT).
      step 1, "persist + flush + post-insert ID (scalar entity)" do
        alice = User.new
        alice.username = "alice"

        show "alice.id (before)", alice.@id
        em.persist alice
        em.flush
        show "alice.id (after)", alice.id

        expect("alice got an identity-strategy id") { alice.id > 0 }
        em.clear
      end

      # ---------------------------------------------------------------------
      # The first `find!` issues a SELECT and stores the entity in the identity map.
      # The second `find!` for the same id returns the SAME object — no extra query — so equality checks via `same?` hold.
      step 2, "find by ID + identity-map dedup" do
        first = em.find!(User, 1)
        second = em.find!(User, 1)

        show "first.username", first.username
        show "first.same_as?(second)", first.same?(second)

        expect("hydrated user has username") { first.username == "alice" }
        expect("second find hits identity map (same instance)") { first.same?(second) }
      end

      # ---------------------------------------------------------------------
      # `cascade: ["persist"]` on User.avatar means we only have to persist Bob; the avatar tags along.
      # The UoW also figures out insert order: avatars is inserted FIRST so its generated id is available as the user's avatar_id FK in the same flush.
      step 3, "OneToOne cascade-persist + FK column populated" do
        avatar = Avatar.new
        avatar.url = "https://example.test/bob.png"

        bob = User.new
        bob.username = "bob"
        bob.avatar = AORM::Proxy(Avatar).wrap(avatar)

        em.persist bob
        em.flush

        show "bob.id", bob.id
        show "bob.avatar.id", bob.avatar.try(&.id)

        expect("bob got an id") { bob.id > 0 }
        expect("avatar got an id (cascade-persist)") { avatar.id > 0 }

        # Verify the FK column was populated in the user row.
        avatar_id_in_db = conn.scalar("SELECT avatar_id FROM users WHERE id = #{name == "postgres" ? "$1" : "?"}", bob.id).as(Int)
        show "users.avatar_id (in DB)", avatar_id_in_db
        expect("users.avatar_id matches avatar.id") { avatar_id_in_db == avatar.id }
      end

      # ---------------------------------------------------------------------
      # ManyToMany cascade follows the same shape: persist Carol → her groups also get inserted, and the join-table rows are written automatically after both sides have ids.
      # Note `add_group` keeps both ends of the relationship in sync in-memory — the ORM only writes through the owning side, but you generally want the inverse to reflect reality too.
      step 4, "cascade-persist M2M (insert into user_group)" do
        admins = Group.new
        admins.name = "admins"
        devs = Group.new
        devs.name = "devs"

        carol = User.new
        carol.username = "carol"
        carol.add_group admins
        carol.add_group devs

        em.persist carol
        em.flush

        show "carol.id", carol.id
        show "carol.groups.size", carol.groups.size
        show "admins.id", admins.id
        show "devs.id", devs.id

        join_count = conn.scalar("SELECT COUNT(*) FROM user_group WHERE user_id = #{name == "postgres" ? "$1" : "?"}", carol.id).as(Int64)
        show "user_group rows for carol", join_count

        expect("carol persisted with id") { carol.id > 0 }
        expect("both groups inserted via cascade") { admins.id > 0 && devs.id > 0 }
        expect("two join rows written") { join_count == 2 }
      end

      # ---------------------------------------------------------------------
      # `em.repository(T)` returns a typed `EntityRepository(T)` with the standard finder API (`find`, `find_by`, `find_one_by`, `count`).
      # It's just a convenient front-end over the persister.
      step 5, "repository find_by(criteria, order_by, limit, offset)" do
        repo = em.repository(User)
        page = repo.find_by(order_by: {"username" => "ASC"}, limit: 2, offset: 0)

        show "page.size", page.size
        show "page.map(&.username)", page.map(&.username)

        expect("limit honored") { page.size == 2 }
        expect("ordered ascending by username") { page.map(&.username) == page.map(&.username).sort! }
      end

      # ---------------------------------------------------------------------
      step 6, "count" do
        repo = em.repository(User)
        total = repo.count
        show "User count", total

        expect("3 users in DB") { total == 3 }
      end

      # ---------------------------------------------------------------------
      # Lazy loading: an entity's collections aren't fetched eagerly.
      # They come back from `find!` as initialized=false `PersistentCollection`s, and the actual SELECT only fires the first time you touch them.
      # This avoids the classic N+1 trap of "hydrate everything in case the caller might want it" while still letting `user.groups.size` Just Work.
      step 7, "lazy load: M2M owning side (User.groups)" do
        # Drop the in-memory carol so `find!` actually round-trips to the DB.
        em.clear

        puts "    -- find!(User, 3): expect ONE SELECT for users, none for groups"
        carol = em.find!(User, 3)

        pc = carol.groups.as(AORM::PersistentCollection(Group))
        show "carol.groups.loaded?", pc.loaded?

        expect("groups collection is uninitialized after find!") { !pc.loaded? }

        puts "    -- carol.groups.size: expect the join SELECT to fire NOW"
        size = carol.groups.size

        show "carol.groups.size", size
        show "carol.groups.loaded? (after touch)", pc.loaded?

        expect("collection initialized after first access") { pc.loaded? }
        expect("loaded the expected number of groups") { size == 2 }
      end

      # ---------------------------------------------------------------------
      # The inverse side reads through the same join table from the other end: `Group.users` is annotated `mapped_by: "groups"`, so loading it issues# a SELECT joining user_group → users.
      # Same lazy semantics as the owning side; the only difference is which join column gets used as the filter.
      step 8, "lazy load: M2M inverse side (Group.users via mapped_by)" do
        em.clear

        puts "    -- find!(Group, 1): expect ONE SELECT for groups, none for users"
        admins = em.find!(Group, 1)

        pc = admins.users.as(AORM::PersistentCollection(User))
        show "admins.users.loaded?", pc.loaded?

        expect("users collection is uninitialized after find!") { !pc.loaded? }

        puts "    -- admins.users.size: expect the inverse-side join SELECT to fire NOW"
        size = admins.users.size

        show "admins.users.size", size
        show "admins.users.loaded? (after touch)", pc.loaded?

        expect("collection initialized after first access") { pc.loaded? }
        # carol left admins as part of step 8 below would normally apply, but at
        # this point in the demo nobody has touched user_group yet beyond step 4,
        # so admins still has its single member.
        expect("loaded the expected number of users") { size == 1 }
      end

      # ---------------------------------------------------------------------
      # OneToMany cascade-persist: User.posts is the inverse side, so the ORM can't write the FK on its own — `add_post` flips post.user back to the owner so the FK column gets populated when the cascading insert runs.
      # `cascade: ["persist"]` then takes care of inserting each Post off the parent's `em.persist alice` call.
      step 9, "cascade-persist OneToMany (User.posts -> posts.user_id FK)" do
        em.clear
        alice = em.find!(User, 1)

        first = Post.new
        first.title = "first post"
        second = Post.new
        second.title = "second post"
        alice.add_post first
        alice.add_post second

        em.flush

        show "first.id", first.id
        show "second.id", second.id

        db_count = conn.scalar("SELECT COUNT(*) FROM posts WHERE user_id = #{name == "postgres" ? "$1" : "?"}", alice.id).as(Int64)
        show "posts rows for alice", db_count

        expect("both posts inserted via cascade") { first.id > 0 && second.id > 0 }
        expect("FK column populated for both posts") { db_count == 2 }
      end

      # ---------------------------------------------------------------------
      # Same lazy semantics as M2M: the inverse-side collection only loads when touched.
      # The SELECT here is `WHERE posts.user_id = ?` against the target table directly — no join table needed.
      step 10, "lazy load: OneToMany inverse side (User.posts via mapped_by)" do
        em.clear

        puts "    -- find!(User, 1): expect ONE SELECT for users, none for posts"
        alice = em.find!(User, 1)

        pc = alice.posts.as(AORM::PersistentCollection(Post))
        show "alice.posts.loaded?", pc.loaded?

        expect("posts collection is uninitialized after find!") { !pc.loaded? }

        puts "    -- alice.posts.size: expect the FK SELECT to fire NOW"
        size = alice.posts.size

        show "alice.posts.size", size
        show "alice.posts.loaded? (after touch)", pc.loaded?

        expect("collection initialized after first access") { pc.loaded? }
        expect("loaded the expected number of posts") { size == 2 }
      end

      # ---------------------------------------------------------------------
      # No `update` call needed — modify a property on a managed entity and the ORM diffs against what it loaded on next flush, emitting an UPDATE for exactly the dirty columns.
      step 11, "change tracking -> UPDATE on flush" do
        em.clear
        alice = em.find!(User, 1)
        show "alice.username (before)", alice.username

        alice.username = "alice_renamed"
        alice.active = false
        em.flush

        reloaded = conn.query_one("SELECT username, active FROM users WHERE id = #{name == "postgres" ? "$1" : "?"}", alice.id, as: {username: String, active: Bool})
        show "alice (in DB)", reloaded

        expect("DB row reflects the in-memory change") { reloaded[:username] == "alice_renamed" && reloaded[:active] == false }
      end

      # ---------------------------------------------------------------------
      # Removing an element from a managed M2M collection emits just a DELETE on the join row, leaving both entities (user + group) untouched.
      # The element-level removal is queued and applied when the UoW commits.
      step 12, "remove element from M2M collection -> join-table DELETE" do
        carol = em.find!(User, 3)

        # Force the lazy collection to load so we can mutate it.
        groups = carol.groups
        groups.size

        before = conn.scalar("SELECT COUNT(*) FROM user_group WHERE user_id = #{name == "postgres" ? "$1" : "?"}", carol.id).as(Int64)
        show "user_group rows (before)", before

        removed = groups.first
        groups.as(AORM::PersistentCollection(Group)).remove_element removed
        em.flush

        after = conn.scalar("SELECT COUNT(*) FROM user_group WHERE user_id = #{name == "postgres" ? "$1" : "?"}", carol.id).as(Int64)
        show "user_group rows (after)", after

        expect("one join row deleted") { after == before - 1 }
      end

      # ---------------------------------------------------------------------
      # `em.remove` schedules the entity for deletion.
      # The actual DELETE runs on flush.
      # Join-table rows go away here via the schema's FK CASCADE; the ORM doesn't issue separate DELETEs for them.
      step 13, "remove entity -> DELETE row + cascade join cleanup" do
        carol = em.find!(User, 3)
        em.remove carol
        em.flush

        remaining = conn.scalar("SELECT COUNT(*) FROM users WHERE id = #{name == "postgres" ? "$1" : "?"}", 3).as(Int64)
        join_remaining = conn.scalar("SELECT COUNT(*) FROM user_group WHERE user_id = #{name == "postgres" ? "$1" : "?"}", 3).as(Int64)
        show "users rows for carol", remaining
        show "user_group rows for carol", join_remaining

        expect("user row gone") { remaining == 0 }
        expect("join rows cleaned via FK CASCADE") { join_remaining == 0 }
      end

      # ---------------------------------------------------------------------
      # Native SQL queries hydrate entities from arbitrary SQL.
      # `find_by` / `find_one_by` only filter on the entity's own columns; anything that requires a JOIN, an aggregate, or a vendor-specific construct goes through `em.create_native_query(sql, rsm)`.
      # The `ResultSetMapping` (RSM) tells the hydrator which result columns map to which entity fields, which alias is the root entity, and so on.
      # Bind values via `set_parameter(position, value)`; `?` placeholders in the SQL are rewritten to `$1, $2, ...` for the Postgres driver.
      step 14, "native SQL query with ResultSetMapping (find users by avatar URL)" do
        em.clear

        rsm = AORM::Query::ResultSetMapping.new
        rsm.add_entity_result(User, "u")
        rsm.add_field_result("u", "id", "id")
        rsm.add_field_result("u", "username", "username")

        query = em.create_native_query(<<-SQL, rsm)
        SELECT u.id, u.username
        FROM users u
        JOIN avatars a ON a.id = u.avatar_id
        WHERE a.url = ?
      SQL
        query.set_parameter(1, "https://example.test/bob.png")

        results = query.get_result
        show "results.size", results.size
        show "results.map(&.as(User).username)", results.map(&.as(User).username)

        expect("native query returned exactly the user with the matching avatar URL") { results.size == 1 }
        expect("hydrated as User entity") { results.first.is_a? User }
        expect("hydrated user has the right username") { results.first.as(User).username == "bob" }
      end

      # ---------------------------------------------------------------------
      # Custom repository class. `@[AORMA::Entity(repository_class: UserRepository)]` on the entity tells the EntityManager that `em.repository(User)` should return a `UserRepository` rather than the generic `EntityRepository(User)`.
      step 15, "custom repository class via @[AORMA::Entity(repository_class: ...)]" do
        em.clear

        repo = em.repository(User)
        show "repo.class", repo.class

        bob = repo.find_by_username("bob")
        show "bob.try(&.id)", bob.try(&.id)

        avatar_matches = repo.find_by_avatar_url("https://example.test/bob.png")
        show "avatar_matches.map(&.username)", avatar_matches.map(&.username)

        expect("em.repository(User) returns the custom UserRepository") { repo.is_a? UserRepository }
        expect("typed find_by_username wrapper works") { bob.try(&.username) == "bob" }
        expect("native-query-backed find_by_avatar_url works") { avatar_matches.map(&.username) == ["bob"] }
      end

      # ---------------------------------------------------------------------
      # A ToOne field typed `AORM::Proxy(T)?` loads lazily: hydrating the owner sets an unloaded proxy that only holds the target's id.
      # The target's SELECT fires the first time something other than its id is read through the proxy.
      step 16, "lazy load: ToOne via AORM::Proxy (User.avatar)" do
        em.clear

        puts "    -- find!(User, 2): expect ONE SELECT for users, none for avatars"
        bob = em.find!(User, 2)
        avatar = bob.avatar.not_nil!

        show "avatar.loaded?", avatar.loaded?
        show "avatar.id", avatar.id

        expect("avatar is an unloaded proxy after find!") { !avatar.loaded? }
        expect("reading the id doesn't load it") { !avatar.loaded? }

        puts "    -- avatar.url: expect the avatar SELECT to fire NOW"
        url = avatar.url

        show "avatar.url", url
        show "avatar.loaded? (after touch)", avatar.loaded?

        expect("proxy loaded on first non-id access") { avatar.loaded? }
        expect("loaded the right avatar") { url == "https://example.test/bob.png" }
      end

      # ---------------------------------------------------------------------
      # `Post` includes the `Timestampable` module, so it gets the module's columns and lifecycle callbacks.
      # `PrePersist` set both timestamps when the posts were inserted in step 9, and `PreUpdate` bumps `updated_at` on every UPDATE.
      step 17, "shared columns + lifecycle callbacks from an included module" do
        em.clear

        post = em.repository(Post).find_one_by(title: "first post").not_nil!
        created_at = post.created_at

        show "post.created_at", created_at
        show "post.updated_at", post.updated_at

        expect("PrePersist set both timestamps on insert") { post.updated_at == created_at }

        post.title = "first post (edited)"
        em.flush

        db_updated_at = conn.query_one("SELECT updated_at FROM posts WHERE id = #{name == "postgres" ? "$1" : "?"}", post.id, as: Time)
        show "posts.updated_at (in DB)", db_updated_at

        expect("PreUpdate bumped updated_at") { post.updated_at > created_at }
        expect("the UPDATE wrote the bumped updated_at") { db_updated_at > created_at }
      end

      # ---------------------------------------------------------------------
      # Enum fields are stored as the member's integer value and hydrated back into the enum.
      step 18, "enum field stored as its integer value" do
        post = em.repository(Post).find_one_by(title: "second post").not_nil!
        show "post.status (before)", post.status

        post.status = PostStatus::Published
        em.flush

        db_status = conn.scalar("SELECT status FROM posts WHERE id = #{name == "postgres" ? "$1" : "?"}", post.id)
        show "posts.status (in DB)", db_status

        em.clear
        reloaded = em.find!(Post, post.id)
        show "reloaded.status", reloaded.status

        expect("stored as the member's integer value") { db_status == PostStatus::Published.value }
        expect("hydrated back into the enum") { reloaded.status.published? }
      end

      # ---------------------------------------------------------------------
      # `refresh` reloads a managed entity's fields from the database, discarding changes that haven't been flushed.
      step 19, "refresh discards unflushed changes" do
        alice = em.find!(User, 1)
        alice.username = "not saved"
        show "alice.username (in memory)", alice.username

        em.refresh alice
        show "alice.username (after refresh)", alice.username

        em.flush
        db_username = conn.scalar("SELECT username FROM users WHERE id = #{name == "postgres" ? "$1" : "?"}", alice.id)

        expect("refresh restored the DB value") { alice.username == "alice_renamed" }
        expect("nothing was left to flush") { db_username == "alice_renamed" }
      end

      em.close
    end
  end

  puts
  puts "All steps passed for #{name}."
  puts
  puts
end
