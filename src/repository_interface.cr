# The parent type of every repository, such as `AORM::EntityRepository`.
#
# A custom repository set via the *repository_class* of `AORMA::Entity` must inherit from it, usually via `AORM::EntityRepository`.
abstract class Athena::ORM::RepositoryInterface
end
