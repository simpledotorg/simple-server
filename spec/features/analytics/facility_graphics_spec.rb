require 'rails_helper'

RSpec.feature 'Facility Group Graphics', type: :feature do
  let(:owner) { create :admin, :owner }
  let(:organization) { create :organization }

  let(:facility_group) { create :facility_group, organization: organization }
  let(:facility) { create :facility, facility_group: facility_group }

  let(:blood_pressures_recorded_this_month) { 10 }

  before :each do
    create_list_in_period(
      :blood_pressure,
      blood_pressures_recorded_this_month,
      Date.today.at_beginning_of_month,
      Date.today.at_end_of_month,
      facility: facility
    )
  end

  before :each do
    sign_in(owner)
    visit analytics_facility_graphics_path(facility)
  end

  it 'contains a single graphic with facility group analytics' do
    expect(page).to have_css('div.snapshot')
  end

  describe 'graphics for facility group' do
    it 'contains the some common details' do
      expect(page).to have_content(Date.today.strftime('%B %Y'))
      expect(page).to have_content(organization.name)
      expect(page).to have_content(facility.name)
    end

    it 'contains the number of blood pressures recorded in the month' do
      expect(page).to have_content(I18n.t('analytics.graphics.facility.blood_pressures_recorded_in_month'))
      expect(page).to have_content(blood_pressures_recorded_this_month)
    end
  end
end
