require "./repository_factory_interface"

# Creates the repositories returned by `AORM::EntityManager#repository`, reusing them for each entity manager.
#
# An entity's repository is its custom *repository_class*, see `AORMA::Entity`, or an `AORM::EntityRepository` of the entity otherwise.
struct Athena::ORM::DefaultRepositoryFactory
  include Athena::ORM::RepositoryFactoryInterface

  @repository_map = Hash(String, AORM::RepositoryInterface).new

  # :inherit:
  def repository(em : AORM::EntityManagerInterface, entity_class : AORM::Entity.class) : AORM::RepositoryInterface
    repo_hash = "#{entity_class}#{em.object_id}"

    if repo = @repository_map[repo_hash]?
      return repo
    end

    @repository_map[repo_hash] = create_repository em, entity_class
  end

  private def create_repository(em : AORM::EntityManagerInterface, entity_class : AORM::Entity.class) : AORM::RepositoryInterface
    class_metadata = em.class_metadata entity_class

    if repo_class = class_metadata.custom_repository_class
      return repo_class.new em, class_metadata
    end

    # Per-entity dispatch into a generic `EntityRepository(EntityType)` since
    # generic types can't be built from a runtime `Class` value.
    self.create_default_repository em, entity_class, class_metadata
  end

  # Unreachable in practice: abstract entities and proxies never get here (the metadata factory rejects them first).
  # It exists so dispatching on an `AORM::Entity.class` covers every class, which is what lets `EntityManager#repository` pass an upcast class.
  private def create_default_repository(em : AORM::EntityManagerInterface, entity_class : AORM::Entity.class, class_metadata : AORM::Mapping::ClassInterface) : NoReturn
    raise "BUG: no default repository for #{entity_class}"
  end

  macro finished
    {% for entity in Athena::ORM::Entity.all_subclasses.reject { |t| t.abstract? || t <= Athena::ORM::Proxy } %}
      private def create_default_repository(em : AORM::EntityManagerInterface, entity_class : {{entity.id}}.class, class_metadata : AORM::Mapping::ClassInterface) : AORM::RepositoryInterface
        AORM::EntityRepository({{entity.id}}).new em, class_metadata
      end
    {% end %}
  end
end
