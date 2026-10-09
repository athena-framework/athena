# :nodoc:
abstract struct Athena::ORM::ID::AbstractGenerator
  abstract def generate(em : AORM::EntityManagerInterface, entity : AORM::Entity? = nil)

  # If `true`, must be called _after_ the entity has been inserted.
  def post_insert? : Bool
    false
  end
end
