require 'rails_helper'

RSpec.feature 'Facility Group Analytics', type: :feature do
  let(:owner) { create :admin, :owner }
  let(:facility_group) { create :facility_group }

  before :each do
    sign_in(owner)
    visit analytics_facility_group_path(facility_group)
  end

  it 'contains a link to the graphics page' do
    expect(page).to have_link(nil, href: analytics_facility_group_graphics_path(facility_group))
  end


end
