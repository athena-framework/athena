class DescriptorApplication2 < ACON::Application
  def initialize
    super "My Athena application", "1.0.0"

    self.add DescriptorCommand1.new
    self.add DescriptorCommand2.new
    self.add DescriptorCommand3.new
    self.add DescriptorCommand4.new
  end
end
