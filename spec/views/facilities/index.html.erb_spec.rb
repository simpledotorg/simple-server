require 'rails_helper'

RSpec.describe "facilities/index", type: :view do
  before(:each) do
    assign(:facilities, [
      Facility.create!(
        :name => "Name",
        :street_address => "Street Address",
        :village_or_colony => "Village Or Colony",
        :district => "District",
        :state => "State",
        :country => "Country",
        :pin => "Pin",
        :facility_type => "Facility Type"
      ),
      Facility.create!(
        :name => "Name",
        :street_address => "Street Address",
        :village_or_colony => "Village Or Colony",
        :district => "District",
        :state => "State",
        :country => "Country",
        :pin => "Pin",
        :facility_type => "Facility Type"
      )
    ])
  end

  it "renders a list of facilities" do
    render
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "Street Address".to_s, :count => 2
    assert_select "tr>td", :text => "Village Or Colony".to_s, :count => 2
    assert_select "tr>td", :text => "District".to_s, :count => 2
    assert_select "tr>td", :text => "State".to_s, :count => 2
    assert_select "tr>td", :text => "Country".to_s, :count => 2
    assert_select "tr>td", :text => "Pin".to_s, :count => 2
    assert_select "tr>td", :text => "Facility Type".to_s, :count => 2
  end
end
