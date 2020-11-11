require "./spec_helper"

struct PrefixControllerTest < ART::Spec::APITestCase
  def test_it_routes_correctly : Nil
    self.request("GET", "/calendar/events").body.should eq %("events")
    self.request("GET", "/calendar/external").body.should eq %("calendars")
  end

  def test_with_path_param : Nil
    self.request("GET", "/calendar/external/99999999").body.should eq "99999999"
  end

  def test_with_parent_prefixes : Nil
    self.request("GET", "/calendar/athena/child1").body.should eq %("child1 + athena")
  end
end
