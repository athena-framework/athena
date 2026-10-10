# A service that holds a resource, such as a database connection, which should be released once its unit of work, such as a request, is done.
#
# ```
# class ReportFile
#   include ACTR::Service::Closeable
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
# The [Athena Framework](/Framework/) closes each of its `ACTR::Service::Closeable` services once a request is done, even if sending the response failed.
#
# NOTE: A service may be instantiated only in order to close it.
# Acquire the resource lazily, on first use, so that units of work that don't need it don't pay for it.
module Athena::Contracts::Service::Closeable
  # Releases the resource `self` holds.
  abstract def close : Nil
end
