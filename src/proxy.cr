# Lazy ToOne wrapper for owning-side associations.
#
# By default, loading an entity also loads the entity each of its `AORMA::OneToOne` and `AORMA::ManyToOne` fields points to.
# Typing an owning-side field as `AORM::Proxy(Target)?` instead of `Target?` makes it lazy: the field holds a proxy that only knows the target's identifier, and loads the target the first time it's needed.
#
# ```
# @[AORMA::Entity]
# class User < AORM::Entity
#   # ...
#
#   @[AORMA::OneToOne]
#   property avatar : AORM::Proxy(Avatar)? = nil
# end
#
# user = em.find! User, 1 # Doesn't query the user's avatar
# avatar = user.avatar.not_nil!
#
# avatar.loaded? # => false
# avatar.id      # => 10, still not loaded
# avatar.url     # => "https://example.com/avatar.png", loads the avatar
# avatar.loaded? # => true
# ```
#
# The target entity's methods can be called on the proxy directly; any method the proxy doesn't define itself is forwarded to `#inner`, which loads the target on first use.
# `#id` is the exception: when the target's identifier field is named `id`, it's read from the proxy without loading anything.
#
# Since the field holds a proxy, raw entity assignment (`user.avatar = some_avatar`) requires an explicit wrap: `user.avatar = AORM::Proxy(Avatar).wrap(some_avatar)`.
# The wrapped entity is persisted, and cascades, like one assigned to a plain `Target?` field.
#
# ## Identity
#
# The proxy is a separate object from the entity it loads.
# Methods every object has, such as `==`, `hash`, `same?` and `is_a?`, act on the proxy itself rather than being forwarded.
# Code that needs the raw `Target` reference (to pass to a function whose signature expects it, or to do an `is_a?` check against a subclass) calls `#inner` explicitly.
#
# Object identity is NOT preserved across a load: once the proxy loads, `AORM::EntityManager#find` returns the loaded `Target` rather than the proxy, so `proxy.same?(em.find(Avatar, proxy.id))` is `false`.
# Stale proxy references stay functional, delegating to the loaded entity.
#
# NOTE: Owning-side ToOne only.
# Fields mapped with `mapped_by` are always loaded along with their owner, and typing one as a proxy raises when the entity's metadata is built.
#
# TODO: Fields typed as a plain `Target?` load each missing target with its own query once the owner's query has finished, rather than batching them.
class Athena::ORM::Proxy(T) < Athena::ORM::Entity
  # :nodoc:
  def self.create_class_metadata(driver : Athena::ORM::Mapping::Driver::Annotation) : Athena::ORM::Mapping::ClassInterface
    raise "BUG: Proxy(#{T}) reached the metadata factory; lookups for proxies must pass `target_class` (=#{T}) instead of `entity.class`"
  end

  @em : Athena::ORM::EntityManagerInterface?
  @id : Hash(String, ::DB::Any)?

  # Returns the target entity, loading it on the first call.
  #
  # Raises if the target no longer exists in the database.
  getter inner : T do
    # On first call: removes self from the identity map,  loads the target via the persister (which re-registers under the same `(T, id_hash)` slot), caches the result on `@inner`, and returns it.
    # Subsequent calls return the cached value directly.
    em = @em || raise "Proxy(#{T}) is unbound; construct via `Proxy.wrap` if you have a loaded entity, or use `EntityManager#find` instead"
    id = @id || raise "Proxy(#{T}) has no identifier"

    uow = em.unit_of_work
    # Vacate this proxy's identity-map slot before loading so the persister's `register_managed` of the loaded entity doesn't trip the collision check.
    # The guard handles proxies built via `from_id` without going through the UoW (e.g. unit tests).
    uow.remove_from_identity_map self if uow.is_in_identity_map self

    loaded = uow.entity_persister(T).load(id)
    raise "Proxy target #{T} with id #{id.inspect} not found" if loaded.nil?

    loaded.as(T)
  end

  # :nodoc:
  forward_missing_to inner

  protected def initialize(@em : Athena::ORM::EntityManagerInterface, @id : Hash(String, ::DB::Any))
  end

  protected def initialize(@inner : T)
  end

  # Wraps an already-loaded entity.
  # The resulting proxy is `loaded?` from the start and never issues a SELECT.
  #
  # ```
  # user.avatar = AORM::Proxy(Avatar).wrap avatar
  # ```
  def self.wrap(value : T) : self
    new value
  end

  # Idempotent: passing through an existing proxy returns it unchanged.
  def self.wrap(value : Proxy(T)) : Proxy(T)
    value
  end

  # :nodoc:
  #
  # Constructs an unloaded proxy bound to *em* and the target's identifier hash.
  # The first `inner` call loads the proxy via `em.unit_of_work.entity_persister(T).load(id)` and replaces this proxy in the identity map with the loaded entity.
  def self.from_id(em : Athena::ORM::EntityManagerInterface, id : Hash(String, ::DB::Any)) : self
    new em, id
  end

  # :nodoc:
  #
  # The wrapped target class.
  def target_class : Athena::ORM::Entity.class
    T
  end

  # :nodoc:
  #
  # Identifier hash carried by an un-loaded proxy, or nil for proxies built via `wrap`.
  def proxy_id : Hash(String, ::DB::Any)?
    @id
  end

  # Returns `true` if the target entity has been loaded, or the proxy was created by `.wrap`.
  def loaded? : Bool
    !@inner.nil?
  end

  # :nodoc:
  #
  # Non-loading accessor: returns the inner if present, nil otherwise.
  # Used internally during commit to inspect proxies without forcing a SELECT.
  def inner? : T?
    @inner
  end

  def inspect(io : IO) : Nil
    io << "AORM::Proxy(" << T << ", loaded=" << self.loaded? << ')'
  end

  # Allows reading the `#id` of a proxy without triggering a load.
  #
  # This only applies to an identifier field named `id`; if the target has no such field, this raises.
  # Reading an identifier field with any other name, such as `proxy.code`, loads the target like any other forwarded method.
  def id
    # Hardcoded to the method name `id` and the field key `"id"` since that's the standard PK name.
    # Composite PKs and entities whose PK ivar isn't named `id` still trigger a load through `forward_missing_to inner` if calling `proxy.<some_other_pk>`.
    {% begin %}
      {% pk_ivar = T.instance_vars.find { |iv| iv.annotation(::Athena::ORM::Annotations::ID) && iv.name.stringify == "id" } %}
      {% if pk_ivar %}
        {% non_nil_type = pk_ivar.type.nilable? ? pk_ivar.type.union_types.reject(&.nilable?).first : pk_ivar.type %}
        if inner = @inner
          inner.id
        else
          @id.not_nil!["id"].not_nil!.as({{non_nil_type}})
        end
      {% else %}
        raise "Proxy(#{T}) has no field named `id` tagged with @[AORMA::ID]; use `.proxy_id` for the raw identifier hash or `.inner.<your_pk>` to load and read the actual PK value."
      {% end %}
    {% end %}
  end
end
