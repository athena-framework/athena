module Athena::Console::Helper::Interface
  # Sets the `ACON::Helper::HelperSet` related to `self`.
  abstract def helper_set=(helper_set : ACON::Helper::HelperSet?)

  # Returns the `ACON::Helper::HelperSet` related to `self`, if any.
  abstract def helper_set : ACON::Helper::HelperSet?
end
