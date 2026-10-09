# Base type of the exceptions the ORM raises, so they can be rescued together.
#
# TODO: Many errors are still raised as plain `::Exception`s, such as an unsupported mapping or flushing a new entity found through an association that doesn't cascade persists, so rescuing this type doesn't catch every ORM error yet.
class Athena::ORM::Exceptions::ORMException < ::Exception
end
