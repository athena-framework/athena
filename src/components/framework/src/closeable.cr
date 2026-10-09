# A service that holds a resource for the duration of a request, such as a database connection.
#
# Once a request is done, `#close` is called on each `ATH::Closeable` service, even if sending the response failed.
#
# ```
# @[ADI::Register]
# class ReportFile
#   include ATH::Closeable
#
#   @file : File? = nil
#
#   def file : File
#     @file ||= File.tempfile "report"
#   end
#
#   def close : Nil
#     @file.try &.delete
#   end
# end
# ```
#
# NOTE: Every `ATH::Closeable` service is instantiated in order to close it, even if the request didn't use it.
# Acquire the resource lazily, on first use, so that requests that don't need it don't pay for it.
@[ADI::Autoconfigure(tags: [ATH::Closeable::TAG])]
module Athena::Framework::Closeable
  TAG = "athena.closeable"

  # Releases the resource `self` holds.
  abstract def close : Nil
end
