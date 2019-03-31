require "./routing_spec_helper"

do_with_config do
  describe Athena::Routing::View do
    describe "default group" do
      it "should serialize correctly" do
        CLIENT.get("/users/17").body.should eq %({"id":17,"age":123})
      end
    end

    describe "admin group" do
      it "should serialize correctly" do
        CLIENT.get("/admin/users/17").body.should eq %({"password":"monkey"})
      end
    end

    describe "admin + default" do
      it "should serialize correctly" do
        CLIENT.get("/admin/users/17/all").body.should eq %({"id":17,"age":123,"password":"monkey"})
      end
    end
  end
end
