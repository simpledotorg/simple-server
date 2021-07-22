require "rails_helper"

RSpec.describe Reports::FacilityState, {type: :model, reporting_spec: true} do
  describe "Associations" do
    it { should belong_to(:facility) }
  end

  # TODO: extract this into a common utility
  around do |example|
    # We need to enforce a known time for this test, otherwise we will have intermittent failures. For example,
    # if we use live system time, many of these specs will fail after 18:30 UTC (ie 14:30 ET) when on the last day of a month,
    # because that falls into the next day in IST (our reporting time zone). So to prevent confusing failures for
    # developers or CI during North American afternoons, we freeze to a time that will be the end of the month for
    # UTC, ET, and IST. Timezones! 🤯
    Timecop.freeze("June 30 2021 23:00 IST") do
      example.run
    end
  end

  context "registrations" do
    describe "cumulative_registrations" do
      it "has the total registrations from beginning of reporting_months (2018) until current month for every facility" do
        facility = create(:facility)
        two_years_ago = june_2021[:now] - 2.years
        create_list(:patient, 6, registration_facility: facility, recorded_at: two_years_ago)
        create_list(:patient, 3, registration_facility: facility, recorded_at: june_2021[:under_three_months_ago])
        RefreshMaterializedViews.new.refresh_v2
        with_reporting_time_zone do
          expect(described_class
            .where(facility_id: facility.id)
            .where("month_date < ?", two_years_ago)
            .pluck(:cumulative_registrations)).to all eq(nil)

          expect(described_class
            .where(facility_id: facility.id)
            .where("month_date >= ?", two_years_ago)
            .where("month_date < ?", june_2021[:under_three_months_ago])
            .pluck(:cumulative_registrations)).to all eq(6)

          expect(described_class
            .where(facility_id: facility.id)
            .where("month_date >= ?", june_2021[:under_three_months_ago])
            .pluck(:cumulative_registrations)).to all eq(9)
        end
      end
    end

    describe "monthly_registrations" do
      it "has the number of new registrations made that month" do
        facility = create(:facility)
        create_list(:patient, 2, registration_facility: facility, recorded_at: june_2021[:under_12_months_ago])
        create_list(:patient, 3, registration_facility: facility, recorded_at: june_2021[:now] - 2.months)

        RefreshMaterializedViews.new.refresh_v2
        with_reporting_time_zone do
          expect(described_class
            .where(facility_id: facility.id)
            .where("month_date < ?", june_2021[:under_12_months_ago])
            .pluck(:monthly_registrations)).to all be nil

          expect(described_class
            .where(facility_id: facility.id)
            .where("month_date >= ?", june_2021[:under_12_months_ago].to_date)
            .where("month_date <= ?", june_2021[:under_3_months_ago].to_date)
            .pluck(:monthly_registrations)).to eq [2, 0, 0, 0, 0, 0, 0, 0, 0, 3]
        end
      end
    end
  end

  context "assigned patients by care states" do
    pending describe "under_care" do
    end

    pending describe "lost_to_follow_up" do
    end

    pending describe "dead" do
    end
    pending describe "cumulative_assigned_patients" do
    end
  end

  context "treatment outcomes in the last 3 months" do
    pending describe "controlled_under_care" do
    end

    pending describe "uncontrolled_under_care" do
    end

    pending describe "missed_visit_under_care" do
    end

    pending describe "visited_no_bp_under_care" do
    end

    pending describe "missed_visit_lost_to_follow_up" do
    end

    pending describe "visited_no_bp_lost_to_follow_up" do
    end

    pending describe "patients_under_care" do
    end

    pending describe "patients_lost_to_follow_up" do
    end
  end

end