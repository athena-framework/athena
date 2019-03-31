require "./routing_spec_helper"

do_with_config do
  describe Athena::Routing::Renderers do
    describe "custom" do
      it "should render correctly" do
        response = CLIENT.get("/users/custom/17")
        response.body.should eq "<?xml version=\"1.0\"?>\n<user id=\"17\"><age>123</age></user>\n"
        response.headers.includes_word?("Content-Type", "X-CUSTOM-TYPE").should be_true
      end
    end

    describe "ecr" do
      context ".def_to_s" do
        it "should render correctly" do
          CLIENT.get("/users/ecr/17").body.should eq "User 17 is 123 years old."
        end
      end

      context ".render" do
        it "should render correctly" do
          CLIENT.get("/ecr_html").body.should eq "<!DOCTYPE html>\n<html>\n<body>\n\n<h1>Hello John!</h1>\n\n<p>My first paragraph.</p>\n\n</body>\n</html>"
        end
      end
    end

    describe "yaml" do
      it "should render correctly" do
        CLIENT.get("/users/yaml/17").body.should eq "---\nid: 17\nage: 123\n"
      end
    end
  end
end
