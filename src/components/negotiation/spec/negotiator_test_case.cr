abstract struct NegotiatorTestCase < ASPEC::TestCase
  def test_best_exception_handling : Nil
    expect_raises ArgumentError, "priorities should not be empty." do
      @negotiator.best "foo/bar", [] of String
    end

    expect_raises ArgumentError, "The header string should not be empty." do
      @negotiator.best "", {"text/html"}
    end
  end
end
