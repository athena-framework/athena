# Class metadata built by one entity manager, reused by others on the same database.
#
# Without a cache, each entity manager builds the metadata of an entity class the first time it needs it.
# `AORM::EntityManagerFactory` shares one cache between the entity managers it creates.
# When creating entity managers directly, pass the same cache to each of them:
#
# ```
# cache = AORM::Mapping::MetadataCache.new
#
# em = AORM::EntityManager.new connection, metadata_cache: cache
# ```
#
# Metadata depends on the database platform (e.g. which ID generator is used), so a cache must not be shared between databases.
class Athena::ORM::Mapping::MetadataCache
  @metadata = Hash(AORM::Entity.class, ClassInterface).new
  @mutex = Mutex.new

  # :nodoc:
  def []?(entity_class : AORM::Entity.class) : ClassInterface?
    @mutex.synchronize { @metadata[entity_class]? }
  end

  # :nodoc:
  def []=(entity_class : AORM::Entity.class, metadata : ClassInterface) : ClassInterface
    @mutex.synchronize { @metadata[entity_class] = metadata }
  end
end
