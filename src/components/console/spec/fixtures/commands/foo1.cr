class Foo1Command < IOCommand
  protected def configure : Nil
    self
      .name("foo:bar1")
      .description("The foo:bar1 command")
      .aliases("afoobar1")
  end
end
