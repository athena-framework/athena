class FooSubnamespaced1Command < IOCommand
  protected def configure : Nil
    self
      .name("foo:bar:baz")
      .description("The foo:bar:baz command")
      .aliases("foobarbaz")
  end
end
