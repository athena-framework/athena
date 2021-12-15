class FooBarCommand < IOCommand
  protected def configure : Nil
    self
      .name("foobar:foo")
      .description("The foobar:foo command")
  end
end
