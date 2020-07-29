require "./spec_helper"

describe CustomAnnotationListener do
  run_server

  it "with the annotation" do
    headers = CLIENT.get("/with-ann").headers
    headers["ANNOTATION"]?.should eq "true"
    headers["ANNOTATION_VALUE"]?.should eq "1"
  end

  it "without the annotation" do
    headers = CLIENT.get("/without-ann").headers
    headers["ANNOTATION"]?.should be_nil
    headers["ANNOTATION_VALUE"]?.should eq "1"
  end

  it "overriding the class's annotation" do
    headers = CLIENT.get("/with-ann-override").headers
    headers["ANNOTATION"]?.should be_nil
    headers["ANNOTATION_VALUE"]?.should eq "2"
  end
end
