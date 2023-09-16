module Athena::Clock::Aware
  # TODO: Wire this up with an `@[ADI::Required]` annotation.

  setter clock : ACLK? = nil

  def now : ACLK::Interface
    (@clock ||= ACLK.new).now
  end
end
