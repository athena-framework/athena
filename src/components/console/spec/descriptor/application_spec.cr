require "../spec_helper"

private class TestApplication < ACON::Application
  protected def default_commands : Array(ACON::Command)
    [] of ACON::Command
  end
end

struct ApplicationDescriptorTest < ASPEC::TestCase
  @[DataProvider("namespace_provider")]
  def test_namespaces(expected : Array(String), names : Array(String)) : Nil
    app = TestApplication.new "foo"

    names.each do |name|
      app.register name do
        ACON::Command::Status::SUCCESS
      end
    end

    ACON::Descriptor::Application.new(app).namespaces.keys.should eq expected
  end

  def namespace_provider : Tuple
    {
      {["_global"], ["foobar"]},
      {["a", "b"], ["b:foo", "a:foo", "b:bar"]},
      {["_global", "22", "33", "b", "z"], ["z:foo", "1", "33:foo", "b:foo", "22:foo:bar"]},
    }
  end
end
