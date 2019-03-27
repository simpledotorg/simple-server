require 'rails_helper'

RSpec.feature 'Organization management', type: :feature do
  let!(:owner) { create(:admin, :owner) }

  before do
    sign_in(owner)
  end

  describe 'new' do
    it "allows owners to create organizations" do
      visit admin_facilities_path
      click_link "+ Organization"

      fill_in "Name", with: "Test organization"
      fill_in "Description", with: "Test description"

      click_button "Create Organization"

      expect(page).to have_content("Test organization")
    end
  end
end
