# The parent type of every entity.
#
# An entity is an object with an identity that's persisted to a row of a database table, such as a user or an order.
# Inherit from this type and apply the `AORMA::Entity` annotation to define one, then use the other `AORM::Annotations` to map its instance variables to columns and associations:
#
# ```
# @[AORMA::Entity]
# @[AORMA::Table(name: "users")]
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
# Instances are created like any other object, and are persisted via an `AORM::EntityManager`.
#
# ## Sharing Mapped Properties
#
# Mapped properties and lifecycle callbacks can be shared between entities by declaring them in a module that each entity includes:
#
# ```
# module Timestampable
#   @[AORMA::Column]
#   property! created_at : Time
#
#   @[AORMA::PrePersist]
#   def set_created_at : Nil
#     @created_at = Time.utc
#   end
# end
#
# @[AORMA::Entity]
# class Post < AORM::Entity
#   include Timestampable
#
#   # ...
# end
# ```
#
# Or in an abstract parent class without the `AORMA::Entity` annotation, which the entities inherit from:
#
# ```
# abstract class Content < AORM::Entity
#   @[AORMA::Column]
#   @[AORMA::ID]
#   @[AORMA::GeneratedValue]
#   property! id : Int64
#
#   @[AORMA::Column]
#   property! title : String
# end
#
# @[AORMA::Entity]
# class Article < Content
#   @[AORMA::Column]
#   property! body : String
# end
# ```
#
# Either way, each entity maps the shared properties to columns of its own table.
# The abstract parent isn't an entity itself, and has no table of its own.
abstract class Athena::ORM::Entity
  macro inherited
    # :nodoc:
    #
    # Each entity subclass creates and loads its own typed metadata.
    # This preserves the specific type T for macro-based annotation processing.
    def self.create_class_metadata(driver : AORM::Mapping::Driver::Annotation) : AORM::Mapping::ClassInterface
      metadata = AORM::Mapping::Class(self).new(self)
      driver.load_metadata_for_entity(metadata)
      metadata
    end
  end
end
