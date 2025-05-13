module Athena::MIME::TypesGuesserInterface
  abstract def supported? : Bool
  abstract def guess_mime_type(path : String | Path) : String?
end
