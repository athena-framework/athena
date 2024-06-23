@[ADI::Register]
# Handles an exception by converting it into an `ATH::Response` via an `ATH::ErrorRendererInterface`.
#
# This listener defines a `log_exception` protected method that determines how the exception gets logged.
# Non `ATH::Exception::HTTPException`s and server errors are logged as errors.
# Validation errors (`ATH::Exception::UnprocessableEntity`) are logged as notice.
# Everything else is logged as a warning.
# The method can be redefined if different logic is desired.
#
# ```
# struct ATH::Listeners::Error
#   # :inherit:
#   protected def log_exception(exception : ::Exception, & : -> String) : Nil
#     # Don't log anything if an exception is some specific type.
#     return if exception.is_a? MyException
#
#     # Exception types could also include modules to act as interfaces to determine their level, E.g. `include NoticeException`.
#     if exception.is_a? NoticeException
#       Log.notice(exception: exception) { yield }
#       return
#     end
#
#     # Otherwise fallback to the default implementation.
#     previous_def
#   end
# end
# ```
struct Athena::Framework::Listeners::Error
  def initialize(@error_renderer : ATH::ErrorRendererInterface); end

  @[AEDA::AsEventListener(priority: -50)]
  def on_exception(event : ATH::Events::Exception) : Nil
    exception = event.exception

    log_exception(exception) { "Uncaught exception #{exception.inspect} at #{exception.backtrace?.try &.first}" }

    event.response = @error_renderer.render event.exception
  rescue ex : ::Exception
    # Also log exceptions raised when handling an exception
    log_exception(ex) { "Exception raised when handling an exception #{ex.inspect} at #{ex.backtrace?.try &.first}" }

    raise ex
  end

  # Logs the provided *exception*, *yields* if the message will be logged.
  #
  # Applications can redefine this method to customize how exceptions are logged.
  protected def log_exception(exception : ::Exception, & : -> String) : Nil
    if !exception.is_a?(ATH::Exception::HTTPException) || exception.status.server_error?
      # Log non HTTPExceptions and server errors as errors
      Log.error(exception: exception) { yield }
    elsif exception.is_a? ATH::Exception::UnprocessableEntity
      # Log failed validations as notice
      Log.notice(exception: exception) { yield }
    else
      # Log everything else as warnings
      Log.warn(exception: exception) { yield }
    end
  end
end
