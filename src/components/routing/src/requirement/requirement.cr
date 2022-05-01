module Athena::Routing::Requirement
  # Sourced from https://github.com/symfony/symfony/blob/c70be0957a11fd8b7aa687d6173e76724068daa4/src/Symfony/Component/Routing/Requirement/Requirement.php

  ASCII_SLUG = /[A-Za-z0-9]+(?:-[A-Za-z0-9]+)*/
  CATCH_ALL  = /.+/

  # Matches a date string in the format of `YYYY-MM-DD`.
  DATE_YMD    = /[0-9]{4}-(?:0[1-9]|1[012])-(?:0[1-9]|[12][0-9]|(?<!02-)3[01])/
  DIGITS      = /[0-9]+/
  UID_BASE32  = /[0-9A-HJKMNP-TV-Z]{26}/
  UID_BASE58  = /[1-9A-HJ-NP-Za-km-z]{22}/
  UID_RFC4122 = /[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}/
  ULID        = /[0-7][0-9A-HJKMNP-TV-Z]{25}/
  UUID        = /[0-9a-f]{8}-[0-9a-f]{4}-[1-6][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/
  UUID_V1     = /[0-9a-f]{8}-[0-9a-f]{4}-1[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/
  UUID_V3     = /[0-9a-f]{8}-[0-9a-f]{4}-3[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/
  UUID_V4     = /[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/
  UUID_V5     = /[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/
  UUID_V6     = /[0-9a-f]{8}-[0-9a-f]{4}-6[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/
end
