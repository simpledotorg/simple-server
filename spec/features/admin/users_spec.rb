require "rails_helper"

RSpec.feature "User admin", type: :feature do
  let!(:owner) { create(:admin) }
  let!(:user) { create(:user) }
  let!(:bp_1) { create(:blood_pressure, user: user, systolic: 145, diastolic: 95, recorded_at: Time.parse("2019-03-15 8:00am +05:30")) }
  let!(:bp_2) { create(:blood_pressure, user: user, systolic: 115, diastolic: 75, recorded_at: Time.parse("2019-03-15 2:15pm +05:30")) }

  before do
    sign_in(owner)
  end

  describe "show a user" do
    before do
      visit admin_user_path(user)
    end

    it "displays the user's details" do
      expect(page).to have_content(user.full_name)
      expect(page).to have_content(user.phone_number)
      expect(page).to have_content(user.registration_facility.name)
    end

    context "recent BP log" do
      it "displays the user's recent BPs", :aggregate_failures do
        within("#recent-bps") do
          expect(page).to have_selector("th", text: "Facility")
          expect(page).to have_content("145/95")
          expect(page).to have_content("115/75")
        end
      end

      it "only displays one date per day, but multiple times", :aggregate_failures do
        within("#recent-bps") do
          expect(page).to have_content("15-MAR-2019", count: 1)
          expect(page).to have_content("8:00 AM")
          expect(page).to have_content("2:15 PM")
        end
      end
    end
  end
end
