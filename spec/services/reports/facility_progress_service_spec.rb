require "rails_helper"

RSpec.describe Reports::FacilityProgressService, type: :model do
  let(:user) { create(:user) }
  let(:facility) { create(:facility) }

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

  context "daily registratiosn" do
    it "returns counts for HTN or DM patients if diabetes is enabled" do
      facility = create(:facility, enable_diabetes_management: true)
      patient1 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      patient2 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      dm_patient = create(:patient, :diabetes, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      patient3 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 1.minute.ago)

      with_reporting_time_zone do
        service = described_class.new(facility, Period.current)
        expect(service.daily_registrations(3.days.ago)).to eq(3)
        expect(service.daily_registrations(1.days.ago)).to eq(0)
        expect(service.daily_registrations(Date.current)).to eq(1)
      end
    end

    it "returns counts for HTN only if diabetes is not enabled" do
      facility = create(:facility, enable_diabetes_management: false)
      patient1 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      patient2 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      dm_patient = create(:patient, :diabetes, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      patient3 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 1.minute.ago)

      with_reporting_time_zone do
        service = described_class.new(facility, Period.current)
        # d service.send(:daily_registrations_grouped_by_day)
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
        create(:appointment, recorded_at: 2.days.ago, patient: patient1, facility: facility, user: user)
        create(:blood_pressure, recorded_at: 2.days.ago, patient: patient2, facility: facility, user: user)
        create(:blood_pressure, recorded_at: 2.days.ago, patient: patient3, facility: facility, user: user)
        create(:blood_sugar, recorded_at: 2.days.ago, patient: patient4, facility: facility, user: user)
        create(:blood_pressure, recorded_at: 2.minutes.ago, patient: patient2, facility: facility, user: user)

        refresh_views
        with_reporting_time_zone do
          service = described_class.new(facility, Period.current)
          expect(service.daily_follow_ups(2.days.ago)).to eq(3)
          expect(service.daily_follow_ups(1.days.ago)).to eq(0)
          expect(service.daily_follow_ups(Date.current)).to eq(1)
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
        create(:appointment, recorded_at: 7.days.ago, patient: htn_patient1, facility: facility, user: user)
        create(:appointment, recorded_at: 2.days.ago, patient: htn_patient1, facility: facility, user: user)
        create(:blood_pressure, recorded_at: 2.days.ago, patient: htn_patient2, facility: facility, user: user)
        create(:blood_pressure, recorded_at: 2.days.ago, patient: undiagnosed_patient, facility: facility, user: user)
        create(:blood_sugar, recorded_at: 2.days.ago, patient: dm_patient, facility: facility, user: user)
        create(:blood_pressure, recorded_at: 2.minutes.ago, patient: dm_patient, facility: facility, user: user)

        refresh_views
        with_reporting_time_zone do
          service = described_class.new(facility, Period.current)
          expect(service.daily_follow_ups(7.days.ago)).to eq(1)
          expect(service.daily_follow_ups(2.days.ago)).to eq(2)
          expect(service.daily_follow_ups(1.days.ago)).to eq(0)
          expect(service.daily_follow_ups(Date.current)).to eq(0)
        end
      end
    end
  end
end
