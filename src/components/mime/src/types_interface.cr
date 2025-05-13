require "./types_guesser_interface"

module Athena::MIME::TypesInteface
  include Athena::MIME::TypesGuesserInterface

  abstract def extensions(for mime_type : String) : Enumerable(String)
  abstract def mime_types(for extension : String) : Enumerable(String)
end
