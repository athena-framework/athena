# Determines how table and column names are quoted in the SQL the ORM generates.
#
# See `AORM::Mapping::DefaultQuoteStrategy` for the quoting it applies.
#
# TODO: A custom quote strategy can't be configured yet; every entity uses `AORM::Mapping::DefaultQuoteStrategy`.
module Athena::ORM::Mapping::QuoteStrategyInterface
  # Returns *column* in the casing *platform* returns result column names in.
  def sql_result_casing(platform : Platforms::Platform, column : String) : String
    if platform.is_a? Platforms::Postgres
      return column.downcase
    end

    column
  end
end
