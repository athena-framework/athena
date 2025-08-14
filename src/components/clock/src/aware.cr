class Athena::Clock; end

# This module can be included to make a type time aware without having to alter its constructor.
#
# ```
# class Example
#   include Athena::Clock::Aware
#
#   def expired?
#     self.now > some_time_instance
#   end
# end
#
# # Will use a `Athena::Clock` instance if a custom one is not set on the instance.
# example = Example.new
#
# # Or if so desired, explicitly set custom implementation.
# my_clock = MySpecialClock.new
# custom_example = Example.new
# custom_example.clock = my_clock
# ```
module Athena::Clock::Aware
  # TODO: Wire this up with an `@[ADI::Required]` annotation.

  setter clock : ACLK::Interface? = nil

  def now : ::Time
    (@clock ||= ACLK.new).now
  end
end
