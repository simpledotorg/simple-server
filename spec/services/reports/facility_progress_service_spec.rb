require "rails_helper"

RSpec.describe Reports::FacilityProgressService, type: :model do
  let(:user) { create(:user) }
  let(:facility) { create(:facility) }
  let(:seven_days_ago) { 7.days.ago }
  let(:two_days_ago) { 2.days.ago }
  let(:one_day_ago) { 1.day.ago }
  let(:two_minutes_ago) { 2.minutes.ago }

  it "returns all dimension combinations" do
    service = described_class.new(facility, Period.current)
    dimensions = service.dimension_combinations_for(:registrations)
    # (2 diagnosis options) * (4 gender options) + 1 special case of all / all
    expect(dimensions.size).to eq(9)
    expect(dimensions.all? { |d| d.indicator == :registrations }).to be true
    expect(dimensions.count { |d| d.diagnosis == :diabetes }).to eq(4)
    expect(dimensions.count { |d| d.diagnosis == :hypertension }).to eq(4)
    expect(dimensions.count { |d| d.diagnosis == :all }).to eq(1)
  end

  context "control_range" do
    it "returns range of months for control rates going back 12 months (not including current month)" do
      Timecop.freeze("February 15th 2022") do
        service = described_class.new(facility, Period.current)
        expect(service.control_range.to_a.first).to eq(Period.month("February 1st 2021"))
        expect(service.control_range.to_a.last).to eq(Period.month("January 1st 2022"))
      end
    end
  end

  it "matches daily stats for including JSON in the view" do
    facility = create(:facility, enable_diabetes_management: true)
    htn_patient1 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: two_days_ago)
    _htn_patient2 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: two_days_ago)
    _dm_patient = create(:patient, :diabetes, registration_facility: facility, registration_user: user, recorded_at: two_days_ago)
    _htn_patient3 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 1.minute.ago)
    create(:blood_pressure, :with_encounter, recorded_at: two_days_ago, patient: htn_patient1, facility: facility, user: user)

    with_reporting_time_zone do
      refresh_views
      service = described_class.new(facility, Period.current)

      registrations = service.daily_statistics[:daily][:grouped_by_date][:registrations]
      follow_ups = service.daily_statistics[:daily][:grouped_by_date][:follow_ups]
      expect(registrations[seven_days_ago.to_date]).to eq(0)
      expect(follow_ups[seven_days_ago.to_date]).to eq(0)
      expect(registrations[two_days_ago.to_date]).to eq(3)
      expect(follow_ups[two_days_ago.to_date]).to eq(1)
    end
  end

  context "daily registrations" do
    it "returns counts for HTN or DM patients if diabetes is enabled" do
      facility = create(:facility, enable_diabetes_management: true)
      _htn_patient1 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      _htn_patient2 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      _dm_patient = create(:patient, :diabetes, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      _htn_patient3 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 1.minute.ago)

      with_reporting_time_zone do
        service = described_class.new(facility, Period.current)
        expect(service.daily_registrations(3.days.ago)).to eq(3)
        expect(service.daily_registrations(1.days.ago)).to eq(0)
        expect(service.daily_registrations(Date.current)).to eq(1)
      end
    end

    it "returns counts for HTN only if diabetes is not enabled" do
      skip "time zone issues in CI"
      facility = create(:facility, enable_diabetes_management: false)
      _htn_patient1 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      _htn_patient2 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      _dm_patient = create(:patient, :diabetes, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      _htn_patient3 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 1.minute.ago)

      with_reporting_time_zone do
        service = described_class.new(facility, Period.current)
        expect(service.daily_registrations(3.days.ago)).to eq(2)
        expect(service.daily_registrations(1.days.ago)).to eq(0)
        expect(service.daily_registrations(Date.current)).to eq(1)
      end
    end
  end

  context "daily follow up counts" do
    it "returns counts for HTN or DM patients if diabetes is enabled" do
      Timecop.freeze do
        facility = create(:facility, enable_diabetes_management: true)
        patient1 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        patient2 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        patient3 = create(:patient, :without_hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        patient4 = create(:patient, :diabetes, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        one_day_ago # ensure this is set to UTC time zone
        create(:appointment, recorded_at: two_days_ago, patient: patient1, facility: facility, user: user)
        create(:blood_pressure, recorded_at: two_days_ago, patient: patient2, facility: facility, user: user)
        create(:blood_pressure, recorded_at: two_days_ago, patient: patient3, facility: facility, user: user)
        create(:blood_sugar, recorded_at: two_days_ago, patient: patient4, facility: facility, user: user)
        with_reporting_time_zone do
          refresh_views
          service = described_class.new(facility, Period.current)
          expect(service.daily_follow_ups(two_days_ago)).to eq(3)
          expect(service.daily_follow_ups(one_day_ago)).to eq(0)
        end
      end
    end

    it "returns counts for HTN only if diabetes is not enabled" do
      Timecop.freeze do
        facility = create(:facility, enable_diabetes_management: false)
        htn_patient1 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        htn_patient2 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        undiagnosed_patient = create(:patient, :without_hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        dm_patient = create(:patient, :diabetes, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        one_day_ago # ensure this is set to UTC time zone
        create(:appointment, recorded_at: seven_days_ago, patient: htn_patient1, facility: facility, user: user)
        create(:appointment, recorded_at: two_days_ago, patient: htn_patient1, facility: facility, user: user)
        create(:blood_pressure, recorded_at: two_days_ago, patient: htn_patient2, facility: facility, user: user)
        create(:blood_pressure, recorded_at: two_days_ago, patient: undiagnosed_patient, facility: facility, user: user)
        create(:blood_sugar, recorded_at: two_days_ago, patient: dm_patient, facility: facility, user: user)
        create(:blood_pressure, recorded_at: two_minutes_ago, patient: dm_patient, facility: facility, user: user)

        with_reporting_time_zone do
          refresh_views
          service = described_class.new(facility, Period.current)
          expect(service.daily_follow_ups(seven_days_ago)).to eq(1)
          expect(service.daily_follow_ups(two_days_ago)).to eq(2)
          expect(service.daily_follow_ups(one_day_ago)).to eq(0)
          expect(service.daily_follow_ups(Date.current)).to eq(0)
        end
      end
    end
  end
end
