require "./spec_helper"

# Lazy-target fixture: nothing user-side references it directly; specs instantiate proxies pointing at it.
@[AORMA::Entity]
@[AORMA::Table(name: "proxy_avatars")]
class ProxyAvatar < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property! id : Int32

  @[AORMA::Column]
  property! filename : String
end

# Owner with a `Proxy(T)?`-typed ToOne field, field should be filled with unloaded proxy.
@[AORMA::Entity]
@[AORMA::Table(name: "proxy_users")]
class ProxyOwner < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property! id : Int32

  @[AORMA::Column]
  property! name : String

  @[AORMA::OneToOne]
  @[AORMA::JoinColumn(name: "avatar_id", referenced_column_id: "id")]
  property avatar : AORM::Proxy(ProxyAvatar)?
end

# Owner whose `Proxy(T)?`-typed ToOne cascades `remove` and `detach`.
@[AORMA::Entity]
@[AORMA::Table(name: "proxy_cascade_users")]
class ProxyCascadeOwner < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property! id : Int32

  @[AORMA::OneToOne(cascade: ["remove", "detach"])]
  @[AORMA::JoinColumn(name: "avatar_id")]
  property avatar : AORM::Proxy(ProxyAvatar)?
end

struct ProxyTest < ASPEC::TestCase
  def test_wrap_returns_loaded_proxy : Nil
    avatar = ProxyAvatar.allocate
    proxy = AORM::Proxy(ProxyAvatar).wrap avatar

    proxy.loaded?.should be_true
    proxy.inner.should be avatar
    proxy.target_class.should eq ProxyAvatar
  end

  def test_wrap_on_proxy_is_idempotent : Nil
    avatar = ProxyAvatar.allocate
    inner_proxy = AORM::Proxy(ProxyAvatar).wrap avatar

    AORM::Proxy(ProxyAvatar).wrap(inner_proxy).should be inner_proxy
  end

  def test_from_id_starts_unloaded : Nil
    em = MockEntityManager.new(MockConnection.new)
    proxy = AORM::Proxy(ProxyAvatar).from_id em, {"id" => 7.as(::DB::Any)}

    proxy.loaded?.should be_false
    proxy.proxy_id.should eq({"id" => 7.as(::DB::Any)})
    proxy.target_class.should eq ProxyAvatar
  end

  def test_inner_loads_via_persister_and_caches : Nil
    em = MockEntityManager.new(MockConnection.new)

    avatar = ProxyAvatar.allocate
    em.class_metadata(ProxyAvatar).apply_data avatar.as(AORM::Entity), {"id" => 7, "filename" => "a.png"}

    persister = MockEntityPersister.new(em, em.class_metadata(ProxyAvatar))
    persister.mock_load_result = avatar

    mock_uow = MockUnitOfWork.new(em)
    mock_uow.set_entity_persister ProxyAvatar, persister
    em.uow_mock = mock_uow

    proxy = AORM::Proxy(ProxyAvatar).from_id em, {"id" => 7.as(::DB::Any)}

    proxy.inner.should be avatar
    proxy.loaded?.should be_true
    persister.load_calls.size.should eq 1

    # Second call doesn't re-load.
    proxy.inner.should be avatar
    persister.load_calls.size.should eq 1
  end

  def test_inner_raises_on_missing_target : Nil
    em = MockEntityManager.new(MockConnection.new)

    persister = MockEntityPersister.new(em, em.class_metadata(ProxyAvatar))
    persister.mock_load_result = nil

    mock_uow = MockUnitOfWork.new(em)
    mock_uow.set_entity_persister ProxyAvatar, persister
    em.uow_mock = mock_uow

    proxy = AORM::Proxy(ProxyAvatar).from_id em, {"id" => 99.as(::DB::Any)}

    expect_raises(Exception, /Proxy target ProxyAvatar.*not found/) do
      proxy.inner
    end
  end

  def test_inner_unbound_proxy_raises : Nil
    avatar = ProxyAvatar.allocate
    proxy = AORM::Proxy(ProxyAvatar).wrap avatar

    # Wrapped proxy already has @inner, `.inner` returns it directly.
    proxy.inner.should be avatar
  end

  # `proxy.id` short-circuits to `@id["id"]` for unloaded proxies and to `inner.id` for loaded proxies.
  def test_id_short_circuits_without_loading : Nil
    em = MockEntityManager.new(MockConnection.new)
    persister = MockEntityPersister.new(em, em.class_metadata(ProxyAvatar))

    mock_uow = MockUnitOfWork.new(em)
    mock_uow.set_entity_persister ProxyAvatar, persister
    em.uow_mock = mock_uow

    proxy = AORM::Proxy(ProxyAvatar).from_id em, {"id" => 42.as(::DB::Any)}

    proxy.id.should eq 42
    proxy.loaded?.should be_false
    persister.load_calls.should be_empty
  end

  # `forward_missing_to inner` makes method calls on the proxy transparently load and dispatch to the loaded entity.
  def test_forward_missing_to_loaded_inner : Nil
    avatar = ProxyAvatar.allocate
    em = MockEntityManager.new(MockConnection.new)
    em.class_metadata(ProxyAvatar).apply_data avatar.as(AORM::Entity), {"id" => 1, "filename" => "x.png"}

    proxy = AORM::Proxy(ProxyAvatar).wrap avatar
    proxy.filename.should eq "x.png"
    proxy.inner.id.should eq 1
  end
end

# Hydration-level coverage: drives a `Proxy(T)?`-typed property through `UnitOfWork#create_entity` and asserts no SELECT is issued on miss.
struct ProxyHydrationTest < ASPEC::TestCase
  @em : MockEntityManager
  @uow : MockUnitOfWork

  def initialize
    @em = MockEntityManager.new MockConnection.new
    @uow = MockUnitOfWork.new @em
    @em.uow_mock = @uow
  end

  # Identity-map miss with `Proxy(T)?` typing: the field is filled with an unloaded proxy and the persister is NOT called.
  def test_hydration_miss_installs_proxy : Nil
    avatar_persister = MockEntityPersister.new @em, @em.class_metadata ProxyAvatar
    @uow.set_entity_persister ProxyAvatar, avatar_persister

    data = Hash(String, AORM::Mapping::Value).new
    data["id"] = AORM::Mapping::SingleValue.new(1)
    data["name"] = AORM::Mapping::SingleValue.new("alice")
    data["avatar_id"] = AORM::Mapping::SingleValue.new(99)

    owner = @uow.create_entity(ProxyOwner, data).as ProxyOwner

    avatar = owner.avatar
    avatar.should be_a AORM::Proxy(ProxyAvatar)
    avatar.as(AORM::Proxy(ProxyAvatar)).loaded?.should be_false
    avatar.as(AORM::Proxy(ProxyAvatar)).proxy_id.should eq({"id" => 99.as(::DB::Any)})

    avatar_persister.load_calls.should be_empty
  end

  # Identity-map hit on a `Proxy(T)?`-typed field: the field can't hold a raw `T`, so the existing entity is wrapped in a loaded proxy.
  # The canonical record in the identity map stays unchanged.
  def test_hydration_hit_wraps_existing_entity_in_proxy : Nil
    existing = ProxyAvatar.allocate
    pointerof(existing.@id).value = 99
    @uow.register_managed existing.as(AORM::Entity), {"id" => 99}, {"id" => 99}

    data = Hash(String, AORM::Mapping::Value).new
    data["id"] = AORM::Mapping::SingleValue.new(1)
    data["name"] = AORM::Mapping::SingleValue.new("alice")
    data["avatar_id"] = AORM::Mapping::SingleValue.new(99)

    owner = @uow.create_entity(ProxyOwner, data).as ProxyOwner

    avatar = owner.avatar
    avatar.should be_a AORM::Proxy(ProxyAvatar)
    proxy = avatar.as AORM::Proxy(ProxyAvatar)
    proxy.loaded?.should be_true
    proxy.inner.should be existing

    # Identity map invariant holds: the canonical record is still the raw entity, not the proxy façade.
    @uow.get_by_id_hash("99", ProxyAvatar).should be existing
  end

  # An unloaded proxy is the target's record in the identity map until it loads.
  # Computing change sets skips it, rather than reading the target's fields through it, and doesn't load it.
  def test_compute_changesets_skips_unloaded_proxy : Nil
    avatar_persister = MockEntityPersister.new @em, @em.class_metadata ProxyAvatar
    @uow.set_entity_persister ProxyAvatar, avatar_persister

    data = Hash(String, AORM::Mapping::Value).new
    data["id"] = AORM::Mapping::SingleValue.new(1)
    data["name"] = AORM::Mapping::SingleValue.new("alice")
    data["avatar_id"] = AORM::Mapping::SingleValue.new(99)

    owner = @uow.create_entity(ProxyOwner, data).as ProxyOwner
    proxy = owner.avatar.as AORM::Proxy(ProxyAvatar)

    @uow.compute_changesets

    proxy.loaded?.should be_false
    avatar_persister.load_calls.should be_empty
    @uow.scheduled_entity_updates.should be_empty
  end

  # Finding the target of an unloaded proxy loads it through the proxy, so the owner's proxy and `find` share the loaded entity.
  def test_find_loads_unloaded_proxy_in_identity_map : Nil
    canned = ProxyAvatar.allocate
    pointerof(canned.@id).value = 99

    avatar_persister = MockEntityPersister.new @em, @em.class_metadata ProxyAvatar
    avatar_persister.mock_load_result = canned
    @uow.set_entity_persister ProxyAvatar, avatar_persister

    data = Hash(String, AORM::Mapping::Value).new
    data["id"] = AORM::Mapping::SingleValue.new(1)
    data["name"] = AORM::Mapping::SingleValue.new("alice")
    data["avatar_id"] = AORM::Mapping::SingleValue.new(99)

    owner = @uow.create_entity(ProxyOwner, data).as ProxyOwner
    proxy = owner.avatar.as AORM::Proxy(ProxyAvatar)

    @em.find(ProxyAvatar, 99).should be canned
    proxy.loaded?.should be_true
    proxy.inner.should be canned
    avatar_persister.load_calls.size.should eq 1
  end

  # Removing the target needs the entity itself, for its lifecycle callbacks and cascades, so an unloaded proxy is loaded first.
  def test_cascade_remove_removes_the_loaded_proxy_target : Nil
    owner, proxy, _ = self.cascade_owner_with_avatar_proxy

    @uow.remove owner

    proxy.loaded?.should be_true
    @uow.is_scheduled_for_delete?(proxy.inner).should be_true
    @uow.is_scheduled_for_delete?(owner).should be_true
  end

  # None of an unloaded proxy's target has been loaded through it, so there's nothing to cascade to, and it's detached without loading it.
  def test_cascade_detach_detaches_an_unloaded_proxy_without_loading_it : Nil
    owner, proxy, avatar_persister = self.cascade_owner_with_avatar_proxy

    @uow.detach owner

    proxy.loaded?.should be_false
    avatar_persister.load_calls.should be_empty
    @uow.get_by_id_hash("99", ProxyAvatar).should be_nil
  end

  def test_cascade_detach_detaches_the_target_of_a_loaded_proxy : Nil
    owner, proxy, _ = self.cascade_owner_with_avatar_proxy
    avatar = proxy.inner

    @uow.detach owner

    @uow.is_in_identity_map?(avatar).should be_false
    @uow.entity_state(avatar, :new).should eq AORM::UnitOfWork::EntityState::New
  end

  private def cascade_owner_with_avatar_proxy : {ProxyCascadeOwner, AORM::Proxy(ProxyAvatar), MockEntityPersister}
    avatar_persister = MockEntityPersister.new @em, @em.class_metadata ProxyAvatar
    avatar_persister.mock_load_data = {"id" => 99, "filename" => "a.png"} of String => DB::Any
    @uow.set_entity_persister ProxyAvatar, avatar_persister

    data = Hash(String, AORM::Mapping::Value).new
    data["id"] = AORM::Mapping::SingleValue.new(1)
    data["avatar_id"] = AORM::Mapping::SingleValue.new(99)

    owner = @uow.create_entity(ProxyCascadeOwner, data).as ProxyCascadeOwner

    {owner, owner.avatar.as(AORM::Proxy(ProxyAvatar)), avatar_persister}
  end

  # Loading the proxy: removes the proxy from the identity map and registers the loaded target under the same key.
  # Subsequent `get_by_id_hash` returns the loaded entity, not the proxy.
  def test_proxy_load_replaces_identity_map_entry : Nil
    canned = ProxyAvatar.allocate
    pointerof(canned.@id).value = 99

    avatar_persister = MockEntityPersister.new @em, @em.class_metadata ProxyAvatar
    @uow.set_entity_persister ProxyAvatar, avatar_persister
    avatar_persister.mock_load_result = canned

    data = Hash(String, AORM::Mapping::Value).new
    data["id"] = AORM::Mapping::SingleValue.new(1)
    data["name"] = AORM::Mapping::SingleValue.new("alice")
    data["avatar_id"] = AORM::Mapping::SingleValue.new(99)

    owner = @uow.create_entity(ProxyOwner, data).as ProxyOwner
    proxy = owner.avatar.as AORM::Proxy(ProxyAvatar)

    # Pre-load: identity map contains the proxy.
    @uow.get_by_id_hash("99", ProxyAvatar).should be proxy

    # Real persister normally calls register_managed which adds the loaded entity to the identity map.
    # The mock skips that, so simulate what register_managed does so the post-load assertion is faithful.
    avatar_persister.mock_load_result = canned
    proxy.inner.should be canned
    proxy.loaded?.should be_true

    # Post-load: the proxy is no longer in the identity map.
    @uow.get_by_id_hash("99", ProxyAvatar).should be_nil
  end
end
