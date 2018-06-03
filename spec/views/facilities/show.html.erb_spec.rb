require 'rails_helper'

RSpec.describe "facilities/show", type: :view do
  before(:each) do
    @facility = assign(:facility, Facility.create!(
      :name => "Name",
      :street_address => "Street Address",
      :village_or_colony => "Village Or Colony",
      :district => "District",
      :state => "State",
      :country => "Country",
      :pin => "Pin",
      :facility_type => "Facility Type"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Street Address/)
    expect(rendered).to match(/Village Or Colony/)
    expect(rendered).to match(/District/)
    expect(rendered).to match(/State/)
    expect(rendered).to match(/Country/)
    expect(rendered).to match(/Pin/)
    expect(rendered).to match(/Facility Type/)
  end
end
