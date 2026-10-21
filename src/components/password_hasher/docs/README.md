Passwords should never be stored as is, but as a hash, so that they cannot be recovered if the hashes leak.
Doing so securely requires a slow, salted hashing algorithm such as [bcrypt](https://en.wikipedia.org/wiki/Bcrypt), as fast general purpose hash functions can be brute forced.

The `Athena::PasswordHasher` component hashes passwords, verifies them, and tells when a hash should be updated, e.g. after increasing the cost of the algorithm.
It provides an [APH::Interface](/PasswordHasher/Interface/) with the following implementations:

* [APH::Native](/PasswordHasher/Native/) - Hashes passwords with the Crystal standard libraries' bcrypt
* [APH::Migrating](/PasswordHasher/Migrating/) - Hashes passwords with one hasher, while still verifying the passwords other hashers created

## Installation

First, install the component by adding the following to your `shard.yml`, then running `shards install`:

```yaml
dependencies:
  athena-password_hasher:
    github: athena-framework/password-hasher
    version: ~> 0.1.0
```

## Usage

An [APH::Interface](/PasswordHasher/Interface/) can be used on its own to hash a plain password, and later verify a plain password against it:

```crystal
hasher = APH::Native.new

hash = hasher.hash "password" # => "$2a$13$..."

hasher.verify hash, "password"       # => true
hasher.verify hash, "wrong_password" # => false
```

### Hashing User Passwords

Most of the time, the passwords being hashed belong to users of the application.
Including [APH::PasswordAuthenticatedUserInterface](/PasswordHasher/PasswordAuthenticatedUserInterface/) into the user type allows an [APH::UserPasswordHasher](/PasswordHasher/UserPasswordHasher/) to work with its password:

```crystal
class User
  include APH::PasswordAuthenticatedUserInterface

  # The hashed password.
  property password : String?
end

hasher = APH::UserPasswordHasher.new APH::Factory.new({User => APH::Native.new})

user = User.new
user.password = hasher.hash_password user, "password"

hasher.password_valid? user, "password" # => true
```

The [APH::Factory](/PasswordHasher/Factory/) decides which hasher to use for a user.
Hashers are configured per type, given as is or by its fully qualified name, which also matches the subtypes and includers of that type.
For example, `APH::PasswordAuthenticatedUserInterface` may be used to configure the hasher of every user type.
A user may also choose the hasher used for its password by name, via the [APH::PasswordHasherAwareInterface](/PasswordHasher/PasswordHasherAwareInterface/).

### Upgrading Hashes

Over time, the cost of a hashing algorithm should be increased as hardware gets faster, or the algorithm itself replaced by a stronger one.
Hashes can only be updated when the plain password is known, so the best time to do it is when a user logs in:

```crystal
if hasher.password_valid? user, plain_password
  if hasher.needs_rehash? user
    user.password = hasher.hash_password user, plain_password
    # Persist the user
  end

  # Log the user in
end
```

Increasing the cost of an [APH::Native](/PasswordHasher/Native/) hasher is enough to make existing hashes need a rehash, as the cost is stored within the hash.
To switch to a different algorithm, an [APH::Migrating](/PasswordHasher/Migrating/) hasher verifies the existing hashes with the previous hasher, while new hashes are created with the new one.

### Custom Hashers

Other algorithms, such as argon2, can be used by implementing [APH::Interface](/PasswordHasher/Interface/), for example with a third-party shard providing the algorithm itself.
The custom hasher may then be used with any of the types of the component.

```crystal
class Argon2Hasher
  include APH::Interface

  # :inherit:
  def hash(plain_password : String) : String
    # ...
  end

  # :inherit:
  def verify(hashed_password : String, plain_password : String) : Bool
    # ...
  end

  # :inherit:
  def needs_rehash?(hashed_password : String) : Bool
    # ...
  end
end

hasher = APH::UserPasswordHasher.new APH::Factory.new({User => APH::Migrating.new(Argon2Hasher.new, APH::Native.new)})
```

### Hashing Passwords from the Command Line

When the [Console](/Console/) component is installed, the component also provides the `security:hash-password` command via [APH::Commands::UserPasswordHash](/PasswordHasher/Commands/UserPasswordHash/).
It is useful to create the hash of a password while developing an application, e.g. to insert a user into the database.

```text
$ ./bin/console security:hash-password

Athena Password Hash Utility
============================

 Type in your password to be hashed:
 >
 --------------- --------------------------------------------------------------
  Key             Value
 --------------- --------------------------------------------------------------
  Hasher used     Athena::PasswordHasher::Native
  Password hash   $2a$13$OXGeRAmufse10/PKTENJsODMUyfiCsiPYod9od/8N9LUitZB49Qq6
 --------------- --------------------------------------------------------------

 ! [NOTE] Self-salting hasher used: the hasher generated its own built-in salt.

 [OK] Password hashing succeeded
```
