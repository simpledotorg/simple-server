require 'rails_helper'

RSpec.feature 'Facility Group Graphics', type: :feature do
  let(:owner) { create :admin, :owner }
  let(:organization) { create :organization }

  let(:facility_group) { create :facility_group, organization: organization }


  before :each do
    sign_in(owner)
    visit analytics_facility_group_graphics_path(facility_group)
  end

  it 'contains a single graphic with facility group analytics' do
    expect(page).to have_css('div.snapshot')
  end

  describe 'graphics for facility group' do
    it 'contains the some common details' do
      expect(page).to have_content(Date.today.strftime('%B %Y'))
      expect(page).to have_content(organization.name)
      expect(page).to have_content(facility_group.name)
    end

    it 'contains the number of newly enrolled patients' do
      expect(page).to have_content(I18n.t('analytics.graphics.facility_groups.newly_enrolled'))
    end
  end
end
