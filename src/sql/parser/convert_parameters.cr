# :nodoc:
module Athena::ORM::SQL
  # :nodoc:
  #
  # Visitor that converts positional (?) and named (:name) parameters
  # to PostgreSQL-style indexed placeholders ($1, $2, etc.).
  class ConvertParameters
    include Visitor

    # Returns the converted SQL string with $n placeholders.
    getter sql : String { @buffer.join }

    # Maps original parameter references to their positions.
    # - For positional params: maps the original 1-based position (Int32) to the new position
    # - For named params: maps the parameter name including colon (String) to the position
    getter parameter_map : Hash(String | Int32, Int32)

    def initialize
      @buffer = [] of String
      @parameter_map = {} of String | Int32 => Int32
      @positional_count = 0
    end

    def accept_positional_parameter(sql : String) : Nil
      @positional_count += 1
      position = @parameter_map.size + 1
      @parameter_map[@positional_count] = position
      @buffer << "$#{position}"
    end

    def accept_named_parameter(sql : String) : Nil
      # Check if we've seen this named parameter before
      if existing_position = @parameter_map[sql]?
        @buffer << "$#{existing_position}"
      else
        position = @parameter_map.size + 1
        @parameter_map[sql] = position
        @buffer << "$#{position}"
      end
    end

    def accept_other(sql : String) : Nil
      @buffer << sql
    end
  end
end
