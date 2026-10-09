# :nodoc:
module Athena::ORM::SQL
  # :nodoc:
  module Visitor
    # Called for positional parameters (?)
    abstract def accept_positional_parameter(sql : String) : Nil

    # Called for named parameters (:name)
    abstract def accept_named_parameter(sql : String) : Nil

    # Called for other SQL fragments (literals, identifiers, comments, etc.)
    abstract def accept_other(sql : String) : Nil
  end
end
