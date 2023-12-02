require "./config"

# Configuration options for `ATH::Listeners::View`. See `.configure`.
@[ACFA::Resolvable("routing.view_handler")]
struct Athena::Framework::Config::ViewHandler
  # This method should be overridden in order to provide configuration overrides for `ATH::View::ViewHandlerInterface`.
  # See the [external documentation](../../../architecture/negotiation.md) for more details.
  #
  # NOTE: The `#failed_validation_status` is currently not used. Included for future work.
  #
  # ```
  # def ATH::Config::ViewHandler.configure : ATH::Config::ViewHandler
  #   new(
  #     empty_content_status: :ok
  #   )
  # end
  # ```
  def self.configure : self
    new
  end

  # The `HTTP::Status` used when there is no response content.
  getter empty_content_status : HTTP::Status

  # The `HTTP::Status` used when validations fail.
  #
  # Currently not used. Included for future work.
  getter failed_validation_status : HTTP::Status

  # If `nil` values should be serialized.
  getter? emit_nil : Bool

  # See `.configure`.
  def initialize(
    @empty_content_status : HTTP::Status = HTTP::Status::NO_CONTENT,
    @failed_validation_status : HTTP::Status = HTTP::Status::UNPROCESSABLE_ENTITY,
    @emit_nil : Bool = false
  )
  end
end
