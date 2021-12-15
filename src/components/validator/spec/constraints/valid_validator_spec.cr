require "../spec_helper"

class FooBarBaz
  include AVD::Validatable

  @[Assert::NotBlank(groups: ["nested"])]
  @foo : String? = nil
end

class FooBar
  include AVD::Validatable

  @[Assert::Valid(groups: ["nested"])]
  @foo_bar_baz : FooBarBaz = FooBarBaz.new
end

class Foo
  include AVD::Validatable

  @[Assert::Valid(groups: ["nested"])]
  setter foo_bar : FooBar? = FooBar.new
end

describe AVD::Constraints::Valid::Validator do
  it "should pass property paths to nested contexts" do
    violations = AVD.validator.validate Foo.new, groups: "nested"

    violations.size.should eq 1
    violations[0].property_path.should eq "foo_bar.foo_bar_baz.foo"
  end

  it "should pass with null value" do
    foo = Foo.new
    foo.foo_bar = nil

    violations = AVD.validator.validate foo, groups: "nested"

    violations.should be_empty
  end
end
