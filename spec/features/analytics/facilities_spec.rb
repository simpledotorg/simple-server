require "rails_helper"

RSpec.feature "Facility analytics", type: :feature do
  let!(:owner) { create(:admin) }
  let!(:facility) { create(:facility) }
  let!(:other_facility) { create(:facility) }
  let!(:bp_1) { create(:blood_pressure, facility: facility, systolic: 145, diastolic: 95, recorded_at: Time.zone.parse("2019-03-15 8:00am +05:30")) }
  let!(:bp_2) { create(:blood_pressure, facility: facility, systolic: 115, diastolic: 75, recorded_at: Time.zone.parse("2019-03-15 2:15pm +05:30")) }

  before do
    sign_in(owner)
  end

  describe "show a facility" do
    before do
      visit analytics_facility_path(facility)
    end

    context "recent BP log" do
      it "displays the facility's recent BPs", :aggregate_failures do
        within("#recent-bps") do
          expect(page).to have_selector("th", text: "Recorded by")
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

  describe "allows period switching" do
    before do
      visit analytics_facility_path(facility)
      click_link "Quarterly report"
    end

    it "shows quarterly metrics" do
      expect(page).to have_content("patients registered in")
      expect(page).to have_content("Result from last visit in")
    end

    it "persists period selection across views" do
      visit analytics_facility_path(other_facility)
      expect(page).to have_content("patients registered in")
      expect(page).to have_content("Result from last visit in")
    end
  end
end
