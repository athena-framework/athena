# Common logic shared between all question types.
# See each type for more information.
module Athena::Console::Question::Base(T)
  # Returns the question that should be asked.
  getter question : String

  # Returns the default value if no valid input is provided.
  getter default : T

  # Returns the answer should be hidden.
  # See [Hiding User Input][Athena::Console::Question--hiding-user-input].
  getter? hidden : Bool = false

  # If hidden questions should fallback on making the response visible if it was unable to be hidden.
  # See [Hiding User Input][Athena::Console::Question--hiding-user-input].
  property? hidden_fallback : Bool = true

  # Returns how many attempts the user has to enter a valid value when a `#validator` is set.
  # See [Validating the Answer][Athena::Console::Question--validating-the-answer].
  getter max_attempts : Int32? = nil

  # :nodoc:
  getter autocompleter_callback : Proc(String, Array(String))? = nil

  # See [Normalizing the Answer][Athena::Console::Question--normalizing-the-answer].
  property normalizer : Proc(T | String, T)? = nil

  # If multi line text should be allowed in the response.
  # See [Multiline Input][Athena::Console::Question--multiline-input].
  property? multi_line : Bool = false

  # Returns/sets if the answer value should be automatically [trimmed](https://crystal-lang.org/api/String.html#strip%3AString-instance-method).
  # See [Trimming the Answer][Athena::Console::Question--trimming-the-answer].
  property? trimmable : Bool = true

  def initialize(@question : String, @default : T)
    {% T.raise "An ACON::Question generic argument cannot be 'Nil'. Use 'String?' instead." if T == Nil %}
  end

  # :nodoc:
  def autocompleter_values : Array(String)?
    if callback = @autocompleter_callback
      return callback.call ""
    end

    nil
  end

  # :nodoc:
  def autocompleter_values=(values : Hash(String, _)?) : self
    self.autocompleter_values = values.keys + values.values
  end

  # :nodoc:
  def autocompleter_values=(values : Hash?) : self
    self.autocompleter_values = values.values
  end

  # :nodoc:
  def autocompleter_values=(values : Indexable?) : self
    if values.nil?
      @autocompleter_callback = nil
      return self
    end

    callback = Proc(String, Array(String)).new do
      values.to_a
    end

    self.autocompleter_callback &callback

    self
  end

  # :nodoc:
  def autocompleter_callback(&block : String -> Array(String)) : Nil
    raise ACON::Exception::Logic.new "A hidden question cannot use the autocompleter." if @hidden

    @autocompleter_callback = block
  end

  # Sets if the answer should be *hidden*.
  # See [Hiding User Input][Athena::Console::Question--hiding-user-input].
  def hidden=(hidden : Bool) : self
    raise ACON::Exception::Logic.new "A hidden question cannot use the autocompleter." if @autocompleter_callback

    @hidden = hidden

    self
  end

  # Allow at most *attempts* for the user to enter a valid value when a `#validator` is set.
  # If *attempts* is `nil`, they have an unlimited amount.
  #
  # See [Validating the Answer][Athena::Console::Question--validating-the-answer].
  def max_attempts=(attempts : Int32?) : self
    raise ACON::Exception::InvalidArgument.new "Maximum number of attempts must be a positive value." if attempts && attempts < 0

    @max_attempts = attempts
    self
  end

  # Sets the normalizer callback to this block.
  # See [Normalizing the Answer][Athena::Console::Question--normalizing-the-answer].
  def normalizer(&@normalizer : T | String -> T) : Nil
  end

  protected def process_response(response : String)
    response = response.presence || @default

    # Only call the normalizer with the actual response or a non nil default.
    if (normalizer = @normalizer) && !response.nil?
      return normalizer.call response
    end

    response.as T
  end
end
