require "./routing_spec_helper"

describe Athena::Routing::Callback do
  describe "user endpoint" do
    it "should set the correct headers" do
      headers = CLIENT.get("/callback/users").headers
      headers.includes_word?("X-RESPONSE-ALL-ROUTES", "true").should be_true
      headers.includes_word?("X-RESPONSE-USER-ROUTE", "true").should be_true
      headers.includes_word?("X-REQUEST-NOT-POSTS-ROUTE", "true").should be_true
      headers.get?("X-RESPONSE-GLOBAL").should_not be_nil
    end
  end

  describe "all endpoint" do
    it "should set the correct headers" do
      headers = CLIENT.get("/callback/all").headers
      headers.includes_word?("X-RESPONSE-ALL-ROUTES", "true").should be_true
      headers.includes_word?("X-RESPONSE-USER-ROUTE", "true").should be_false
      headers.includes_word?("X-REQUEST-NOT-POSTS-ROUTE", "true").should be_true
      headers.get?("X-RESPONSE-GLOBAL").should_not be_nil
    end
  end

  describe "for an excluded endpoint" do
    it "should set the correct headers" do
      headers = CLIENT.get("/callback/posts").headers
      headers.includes_word?("X-RESPONSE-ALL-ROUTES", "true").should be_true
      headers.includes_word?("X-RESPONSE-USER-ROUTE", "true").should be_false
      headers.includes_word?("X-REQUEST-NOT-POSTS-ROUTE", "true").should be_false
      headers.get?("X-RESPONSE-GLOBAL").should be_nil
    end
  end

  describe "in another controller" do
    headers = CLIENT.get("/callback/other").headers

    it "should not set the `CallbackController`'s' headers" do
      headers.includes_word?("X-RESPONSE-ALL-ROUTES", "true").should be_false
      headers.includes_word?("X-RESPONSE-USER-ROUTE", "true").should be_false
      headers.includes_word?("X-REQUEST-NOT-POSTS-ROUTE", "true").should be_false
      headers.get?("X-RESPONSE-GLOBAL").should_not be_nil
    end

    it "should set the global callback header" do
      headers.get?("X-RESPONSE-GLOBAL").should_not be_nil
    end
  end

  describe "inheritence" do
    context "parent" do
      it "should have just the parent header" do
        headers = CLIENT.get("/callback/nested/parent").headers
        global_header = headers.get("X-RESPONSE-GLOBAL")
        global_header.should_not be_nil

        parent_header = headers.get("X-RESPONSE-PARENT")
        parent_header.should_not be_nil

        (global_header.first.to_i64 <= parent_header.first.to_i64).should be_true

        headers.has_key?("X-RESPONSE-CHILD1").should be_false
        headers.has_key?("X-RESPONSE-CHILD2").should be_false
      end
    end

    context "child1" do
      it "should have the parent and child1 headers" do
        headers = CLIENT.get("/callback/nested/child").headers
        global_header = headers.get("X-RESPONSE-GLOBAL")
        global_header.should_not be_nil

        parent_header = headers.get("X-RESPONSE-PARENT")
        parent_header.should_not be_nil

        child1_header = headers.get("X-RESPONSE-CHILD1")
        child1_header.should_not be_nil

        (global_header.first.to_i64 <= parent_header.first.to_i64 < child1_header.first.to_i64).should be_true

        child2_header = headers.get?("X-RESPONSE-CHILD2")
        child2_header.should be_nil
      end
    end

    context "child2" do
      it "should have the parent, child1 and child2 headers" do
        headers = CLIENT.get("/callback/nested/child2").headers
        global_header = headers.get("X-RESPONSE-GLOBAL")
        global_header.should_not be_nil

        parent_header = headers.get("X-RESPONSE-PARENT")
        parent_header.should_not be_nil

        child1_header = headers.get("X-RESPONSE-CHILD1")
        child1_header.should_not be_nil

        child2_header = headers.get("X-RESPONSE-CHILD2")
        child2_header.should_not be_nil

        (parent_header.first.to_i64 < child1_header.first.to_i64 < child2_header.first.to_i64).should be_true
      end
    end

    context "child3" do
      it "should have the parent header" do
        headers = CLIENT.get("/callback/nested/child3").headers
        global_header = headers.get("X-RESPONSE-GLOBAL")
        global_header.should_not be_nil

        parent_header = headers.get("X-RESPONSE-PARENT")
        parent_header.should_not be_nil

        (global_header.first.to_i64 <= parent_header.first.to_i64).should be_true

        child1_header = headers.get?("X-RESPONSE-CHILD1")
        child1_header.should be_nil

        child2_header = headers.get?("X-RESPONSE-CHILD2")
        child2_header.should be_nil
      end
    end
  end
end
