require "./routing_spec_helper"

describe Athena::Routing::Callback do
  describe "user endpoint" do
    it "should set the correct headers" do
      headers = CLIENT.get("/callback/users").headers
      headers.includes_word?("X-RESPONSE-ALL-ROUTES", "true").should be_true
      headers.includes_word?("X-RESPONSE-USER-ROUTE", "true").should be_true
      headers.includes_word?("X-REQUEST-NOT-POSTS-ROUTE", "true").should be_true
      headers.includes_word?("X-RESPONSE-GLOBAL", "true").should be_true
    end
  end

  describe "all endpoint" do
    it "should set the correct headers" do
      headers = CLIENT.get("/callback/all").headers
      headers.includes_word?("X-RESPONSE-ALL-ROUTES", "true").should be_true
      headers.includes_word?("X-RESPONSE-USER-ROUTE", "true").should be_false
      headers.includes_word?("X-REQUEST-NOT-POSTS-ROUTE", "true").should be_true
      headers.includes_word?("X-RESPONSE-GLOBAL", "true").should be_true
    end
  end

  describe "posts endpoint" do
    it "should set the correct headers" do
      headers = CLIENT.get("/callback/posts").headers
      headers.includes_word?("X-RESPONSE-ALL-ROUTES", "true").should be_true
      headers.includes_word?("X-RESPONSE-USER-ROUTE", "true").should be_false
      headers.includes_word?("X-REQUEST-NOT-POSTS-ROUTE", "true").should be_false
      headers.includes_word?("X-RESPONSE-GLOBAL", "true").should be_false
    end
  end

  describe "in another controller" do
    headers = CLIENT.get("/callback/other").headers

    it "should not set the `CallbackController`'s' headers" do
      headers.includes_word?("X-RESPONSE-ALL-ROUTES", "true").should be_false
      headers.includes_word?("X-RESPONSE-USER-ROUTE", "true").should be_false
      headers.includes_word?("X-REQUEST-NOT-POSTS-ROUTE", "true").should be_false
      headers.includes_word?("X-RESPONSE-GLOBAL", "true").should be_true
    end

    it "should set the global callback header" do
      headers.includes_word?("X-RESPONSE-GLOBAL", "true").should be_true
    end
  end

  describe "inheritence" do
    context "parent" do
      it "should have just the parent header" do
        headers = CLIENT.get("/callback/nested/parent").headers
        headers.includes_word?("X-RESPONSE-PARENT", "true").should be_true
        headers.includes_word?("X-RESPONSE-CHILD1", "true").should be_false
        headers.includes_word?("X-RESPONSE-CHILD2", "true").should be_false
      end
    end

    context "child1" do
      it "should have the parent and child1 headers" do
        headers = CLIENT.get("/callback/nested/child").headers
        headers.includes_word?("X-RESPONSE-PARENT", "true").should be_true
        headers.includes_word?("X-RESPONSE-CHILD1", "true").should be_true
        headers.includes_word?("X-RESPONSE-CHILD2", "true").should be_false
      end
    end

    context "child2" do
      it "should have the parent, child1 and child2 headers" do
        headers = CLIENT.get("/callback/nested/child2").headers
        headers.includes_word?("X-RESPONSE-PARENT", "true").should be_true
        headers.includes_word?("X-RESPONSE-CHILD1", "true").should be_true
        headers.includes_word?("X-RESPONSE-CHILD2", "true").should be_true
      end
    end

    context "child3" do
      it "should have the parent header" do
        headers = CLIENT.get("/callback/nested/child3").headers
        headers.includes_word?("X-RESPONSE-PARENT", "true").should be_true
        headers.includes_word?("X-RESPONSE-CHILD1", "true").should be_false
        headers.includes_word?("X-RESPONSE-CHILD2", "true").should be_false
      end
    end
  end
end
