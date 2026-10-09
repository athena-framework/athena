require "./abstract_generator"

# :nodoc:
struct Athena::ORM::ID::SequenceGenerator < Athena::ORM::ID::AbstractGenerator
  getter next_value : Int64 = 0
  getter max_value : Int64? = nil

  def initialize(@sequence_name : String, @allocation_size : Int64); end

  def generate(em : AORM::EntityManagerInterface, entity : AORM::Entity? = nil)
    if @max_value.nil? || @max_value == @next_value
      connection = em.connection
      sql = connection.database_platform.sequence_next_value_sql @sequence_name

      @next_value = case id = connection.scalar(sql)
                    when Int then id.to_i64
                    else
                      raise "BUG: Invalid number"
                    end
      @max_value = @next_value + @allocation_size
    end

    value = @next_value

    @next_value += 1

    value
  end
end
