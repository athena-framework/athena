require "./abstract_generator"

# :nodoc:
struct Athena::ORM::ID::IdentityGenerator < Athena::ORM::ID::AbstractGenerator
  # :inherit:
  def generate(em : AORM::EntityManagerInterface, entity : AORM::Entity? = nil)
    em.connection.last_insert_id
  end

  # :inherit:
  def post_insert? : Bool
    true
  end
end
