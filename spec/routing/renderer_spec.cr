require "./routing_spec_helper"

do_with_config do |client|
  describe Athena::Routing::Renderers do
    describe "custom" do
      it "should render correctly" do
        response = client.get("/users/custom/17")
        response.body.should eq "<?xml version=\"1.0\"?>\n<user id=\"17\"><age>123</age></user>\n"
        response.headers.includes_word?("Content-Type", "X-CUSTOM-TYPE").should be_true
      end
    end

    describe "ECR" do
      context ".def_to_s" do
        it "should render correctly" do
          response = client.get("/users/ecr/17")
          response.body.should eq "User 17 is 123 years old."
          response.headers["Content-Type"].should eq "text/html; charset=utf-8"
        end
      end

      context ".render" do
        it "should render correctly" do
          response = client.get("/ecr_html")
          response.body.should eq "<!DOCTYPE html>\n<html>\n<body>\n\n<h1>Hello John!</h1>\n\n<p>My first paragraph.</p>\n\n</body>\n</html>"
          response.headers["Content-Type"].should eq "text/html; charset=utf-8"
        end
      end
    end

    describe "YAML" do
      it "should render correctly" do
        response = client.get("/users/yaml/17")
        response.body.should eq "---\nid: 17\nage: 123\n"
        response.headers["Content-Type"].should eq "text/x-yaml; charset=utf-8"
      end
    end

    describe "JSON" do
      it "should render correctly" do
        response = client.get("/users/17")
        response.body.should eq %({"id":17,"age":123})
        response.headers["Content-Type"].should eq "application/json; charset=utf-8"
      end
    end
  end
end
