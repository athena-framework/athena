# Parent of the reasons a column's type can't be declared, see `InvalidColumnDeclaration`.
abstract class Athena::ORM::Exception::InvalidColumnType < ::Exception
  include Athena::ORM::Exception
end
