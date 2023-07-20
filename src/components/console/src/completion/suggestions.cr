class Athena::Console::Completion::Suggestions
  record SuggestedValue, value : String, description : String = "" do
    def to_s(io : IO) : Nil
      @value.to_s io
    end
  end

  getter suggested_options = [] of ACON::Input::Option
  getter suggested_values = [] of SuggestedValue

  def suggest_value(value : String, description : String = "") : self
    self.suggest_value SuggestedValue.new value, description
  end

  def suggest_value(value : ACON::Completion::Suggestions::SuggestedValue) : self
    @suggested_values << value

    self
  end

  def suggest_option(option : ACON::Input::Option) : self
    @suggested_options << option

    self
  end

  def suggest_options(options : ::Hash(String, ACON::Input::Option)) : self
    options.each_value do |option|
      self.suggest_option option
    end

    self
  end
end
