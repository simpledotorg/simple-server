# frozen_string_literal: true

require "features_helper"

RSpec.feature "User admin", type: :feature do
  let!(:owner) { create(:admin, :power_user) }
  let!(:user) { create(:user) }
  let!(:bp_1) { create(:blood_pressure, user: user, systolic: 145, diastolic: 95, recorded_at: Time.zone.parse("2019-03-15 8:00am +05:30")) }
  let!(:bp_2) { create(:blood_pressure, user: user, systolic: 115, diastolic: 75, recorded_at: Time.zone.parse("2019-03-15 2:15pm +05:30")) }

  before do
    sign_in(owner.email_authentication)
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
          expect(page).to have_selector("th", text: /facility/i)
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

    context "sync approval status and reason" do
      let!(:sync_approval_allowed_user) { create(:user) }
      let!(:sync_approval_denied_user) { create(:user, :sync_denied) }
      let!(:sync_approval_requested_user) { create(:user, :sync_requested) }

      it "shows the Deny access button when sync approval status is 'allowed'" do
        visit admin_user_path(sync_approval_allowed_user)

        expect(page).to have_selector(:link_or_button, "Deny access")
        expect(page).to have_content("User is allowed")

        expect(page).not_to have_selector(:link_or_button, "Allow access")
      end

      it "shows the Allow access button when sync approval status is 'denied'" do
        visit admin_user_path(sync_approval_denied_user)

        expect(page).to have_content("No particular reason")

        expect(page).to have_selector(:link_or_button, "Allow access")
        expect(page).not_to have_selector(:link_or_button, "Deny access")
      end

      it "shows the Deny access and Allow access buttons when sync approval status is 'requested'" do
        visit admin_user_path(sync_approval_requested_user)

        expect(page).to have_content("New registration")

        expect(page).to have_selector(:link_or_button, "Allow access")
        expect(page).to have_selector(:link_or_button, "Deny access")
      end
    end
  end
end
