# Stores all the suggested values/options for the current `ACON::Completion::Input`.
class Athena::Console::Completion::Suggestions
  # Represents a single suggested values, plus optional description.
  record SuggestedValue, value : String, description : String = "" do
    def to_s(io : IO) : Nil
      @value.to_s io
    end
  end

  # Returns an array of the suggested `ACON::Input::Option`s.
  getter suggested_options = [] of ACON::Input::Option

  # Returns an array of the `ACON::Completion::Suggestions::SuggestedValue`s.
  getter suggested_values = [] of ACON::Completion::Suggestions::SuggestedValue

  # Adds each of the provided *values* to `#suggested_values`.
  def suggest_values(*values : String) : self
    self.suggest_values values
  end

  # Adds each of the provided *values* to `#suggested_values`.
  def suggest_values(values : Enumerable(String)) : self
    values.each do |option|
      self.suggest_value option
    end

    self
  end

  # Adds the provided *value*, and optional *description* to `#suggested_values`.
  def suggest_value(value : String, description : String = "") : self
    self.suggest_value SuggestedValue.new value, description
  end

  # Adds the provided *value* to `#suggested_values`.
  def suggest_value(value : ACON::Completion::Suggestions::SuggestedValue) : self
    @suggested_values << value

    self
  end

  # Adds each of the provided *options* to `#suggested_options`.
  def suggest_options(options : ::Enumerable(ACON::Input::Option)) : self
    options.each do |option|
      self.suggest_option option
    end

    self
  end

  # Adds the provided *option* to `#suggested_options`.
  def suggest_option(option : ACON::Input::Option) : self
    @suggested_options << option

    self
  end
end
