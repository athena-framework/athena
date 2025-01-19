class Athena::Clock; end

# Can be used to make a type time aware without having to alter its constructor.
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
# # By default uses an `Athena::Clock` instance
# example = Example.new
#
# # Or use a custom implementation.
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
