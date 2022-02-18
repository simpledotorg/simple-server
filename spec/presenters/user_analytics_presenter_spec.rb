require "rails_helper"

RSpec.describe UserAnalyticsPresenter, type: :model do
  before(:all) do
    refresh_views
  end
  let(:current_user) { create(:user) }
  let(:request_date) { Time.zone.parse("January 1st 2018 12:00").to_date }

  before do
    # we need to refer to this constant before we try to stub_const on it below,
    # otherwise things get weird
    _months_ago = ActivityService::MONTHS_AGO
  end

  describe "#statistics" do
    context "when diabetes management is enabled" do
      let(:current_facility) {
        create(:facility,
          facility_group: current_user.facility.facility_group,
          enable_diabetes_management: true)
      }

      context "all_time" do
        let(:reg_date) { request_date - 3.months }
        let(:follow_up_date) { request_date - 2.months }

        before do
          patients = [create(:patient,
            :hypertension,
            registration_facility: current_facility,
            recorded_at: reg_date,
            gender: "female"),
            create(:patient,
              :hypertension,
              registration_facility: current_facility,
              recorded_at: reg_date,
              gender: "male"),
            create(:patient,
              :diabetes,
              registration_facility: current_facility,
              recorded_at: reg_date,
              gender: "transgender")]

          patients.each do |patient|
            create(:blood_pressure,
              :with_encounter,
              patient: patient,
              facility: current_facility,
              user: current_user,
              recorded_at: follow_up_date)

            create(:blood_sugar,
              :with_encounter,
              patient: patient,
              facility: current_facility,
              user: current_user,
              recorded_at: follow_up_date)
          end
        end
      end
    end

    context "when diabetes management is disabled" do
      let(:current_facility) { create(:facility, facility_group: current_user.facility.facility_group, enable_diabetes_management: false) }

      context "all_time" do
        let(:reg_date) { request_date - 3.months }
        let(:follow_up_date) { request_date - 2.months }

        before do
          patients = [create(:patient,
            :hypertension,
            registration_facility: current_facility,
            recorded_at: reg_date,
            gender: "female"),
            create(:patient,
              :hypertension,
              registration_facility: current_facility,
              recorded_at: reg_date,
              gender: "male"),
            create(:patient,
              :diabetes,
              registration_facility: current_facility,
              recorded_at: reg_date,
              gender: "transgender")]

          patients.each do |patient|
            create(:blood_pressure,
              :with_encounter,
              patient: patient,
              facility: current_facility,
              user: current_user,
              recorded_at: follow_up_date)

            create(:blood_sugar,
              :with_encounter,
              patient: patient,
              facility: current_facility,
              user: current_user,
              recorded_at: follow_up_date)
          end
        end

        it "has data grouped by date" do
          data = described_class.new(current_facility).statistics

          expect(data.dig(:all_time, :grouped_by_date)).to eq(nil)
        end
      end
    end

    context "metadata" do
      let(:current_facility) { create(:facility, facility_group: current_user.facility.facility_group) }

      context "last_updated_at" do
        it "has date for today if request was made today" do
          data = described_class.new(current_facility).statistics

          expect(data.dig(:metadata, :last_updated_at).to_date)
            .to eq(Time.current.to_date)
        end

        it "has the date at which the request was made" do
          two_days_ago = 2.days.ago.to_date

          data = travel_to(two_days_ago) {
            described_class.new(current_facility).statistics
          }

          expect(data.dig(:metadata, :last_updated_at).to_date)
            .to eq(two_days_ago)
        end
      end

      context "formatted_today_string" do
        before do
          @current_locale = I18n.locale
        end

        after do
          I18n.locale = @current_locale
        end

        I18n.available_locales.each do |locale|
          it "is in #{locale}" do
            I18n.locale = locale
            data = described_class.new(current_facility).statistics

            expect(data.dig(:metadata, :today_string)).to eq(I18n.t(:today_str, locale: locale))
          end
        end
      end

      it "has the formatted_next_date" do
        date = Date.new(2020, 1, 1)

        data = travel_to(date) {
          described_class.new(current_facility).statistics
        }

        expect(data.dig(:metadata, :formatted_next_date))
          .to eq("02-JAN-2020")
      end
    end
  end

  describe "#display_percentage" do
    let(:current_facility) { create(:facility, facility_group: current_user.facility.facility_group) }

    it "displays 0% if denominator is zero" do
      expect(described_class.new(current_facility).display_percentage(2, 0)).to eq("0%")
    end

    it "displays 0% if denominator is nil" do
      expect(described_class.new(current_facility).display_percentage(2, nil)).to eq("0%")
    end

    it "displays 0% if numerator is zero" do
      expect(described_class.new(current_facility).display_percentage(0, 3)).to eq("0%")
    end

    it "displays 0% if numerator is nil" do
      expect(described_class.new(current_facility).display_percentage(nil, 2)).to eq("0%")
    end

    it "displays the percentage rounded up" do
      expect(described_class.new(current_facility).display_percentage(22, 7)).to eq("314%")
    end
  end
end
