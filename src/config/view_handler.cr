require "./config"

@[ACFA::Resolvable("routing.view_handler")]
struct Athena::Routing::Config::ViewHandler
  def self.configure : self
    new
  end

  getter empty_content_status : HTTP::Status
  getter failed_validation_status : HTTP::Status

  getter? emit_nil : Bool

  # See `.configure`.
  def initialize(
    @empty_content_status : HTTP::Status = HTTP::Status::NO_CONTENT,
    @failed_validation_status : HTTP::Status = HTTP::Status::UNPROCESSABLE_ENTITY,
    @emit_nil : Bool = false
  )
  end
end
