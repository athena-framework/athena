class Athena::Console::Question(T); end

require "./base"

# Base type of choice based questions.
# See each subclass for more information.
abstract class Athena::Console::Question::AbstractChoice(T, ChoiceType)
  include Athena::Console::Question::Base(T?)

  # Returns the possible choices.
  getter choices : Hash(String | Int32, T)

  # Returns the message to display if the provided answer is not a valid choice.
  getter error_message : String = "Value '%s' is invalid."

  # Returns/sets the prompt to use for the question.
  # The prompt being the character(s) before the user input.
  property prompt : String = " > "

  # See [Validating the Answer][Athena::Console::Question--validating-the-answer].
  property validator : Proc(T?, ChoiceType)? = nil

  def self.new(question : String, choices : Indexable(T), default : Int | T | Nil = nil)
    choices_hash = Hash(String | Int32, T).new

    choices.each_with_index do |choice, idx|
      choices_hash[idx] = choice
    end

    new question, choices_hash, (default.is_a?(Int) ? choices[default]? : default)
  end

  def initialize(question : String, choices : Hash(String | Int32, T), default : T? = nil)
    super question, default

    raise ACON::Exceptions::Logic.new "Choice questions must have at least 1 choice available." if choices.empty?

    @choices = choices.transform_keys &.as String | Int32

    self.validator = ->default_validator(T?)
    self.autocompleter_values = choices
  end

  def error_message=(@error_message : String) : self
    self.validator = ->default_validator(T?)

    self
  end

  # Sets the validator callback to the provided block.
  # See [Validating the Answer][Athena::Console::Question--validating-the-answer].
  def validator(&@validator : T? -> ChoiceType) : Nil
  end

  private def selected_choices(answer : String?) : Array(T)
    selected_choices = self.parse_answers answer

    if @trimmable
      selected_choices.map! &.strip
    end

    valid_choices = [] of String
    selected_choices.each do |value|
      results = [] of String

      @choices.each do |key, choice|
        results << key.to_s if choice == value
      end

      raise ACON::Exceptions::InvalidArgument.new %(The provided answer is ambiguous. Value should be one of #{results.join(" or ") { |i| "'#{i}'" }}.) if results.size > 1

      result = @choices.find { |(k, v)| v == value || k.to_s == value }.try &.first.to_s

      # If none of the keys are a string, assume the original choice values were an Indexable.
      if @choices.keys.none?(String) && result
        result = @choices[result.to_i]
      elsif @choices.has_key? value
        result = @choices[value]
      elsif @choices.has_key? result
        result = @choices[result]
      end

      if result.nil?
        raise ACON::Exceptions::InvalidArgument.new sprintf(@error_message, value)
      end

      valid_choices << result
    end

    valid_choices
  end

  protected abstract def default_validator(answer : T?) : ChoiceType
  protected abstract def parse_answers(answer : T?) : Array(String)
end
