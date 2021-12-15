class FooSubnamespaced2Command < IOCommand
  protected def configure : Nil
    self
      .name("foo:bar:go")
      .description("The foo:bar:go command")
      .aliases("foobargo")
  end
end
