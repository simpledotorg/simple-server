require "rails_helper"

RSpec.describe Reports::FacilityState, {type: :model, reporting_spec: true} do
  describe "Associations" do
    it { should belong_to(:facility) }
  end

  around do |example|
    freeze_time_for_reporting_specs(example)
  end

  context "registrations" do
    describe "cumulative_registrations" do
      it "has the total registrations from beginning of reporting_months (2018) until current month for every facility" do
        facility = create(:facility)
        two_years_ago = june_2021[:now] - 2.years
        create_list(:patient, 6, registration_facility: facility, recorded_at: two_years_ago)
        create_list(:patient, 3, registration_facility: facility, recorded_at: june_2021[:under_three_months_ago])
        RefreshReportingViews.new.refresh_v2
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
        create_list(:patient, 2, registration_facility: facility, recorded_at: june_2021[:under_12_months_ago]) # "2020-07"
        create_list(:patient, 3, registration_facility: facility, recorded_at: june_2021[:under_3_months_ago]) # "2021-04"

        month_2020_07 = "2020-07-01"
        month_2021_04 = "2021-04-01"

        RefreshReportingViews.new.refresh_v2
        with_reporting_time_zone do
          expect(described_class
            .where(facility_id: facility.id)
            .where("month_date < ?", month_2020_07)
            .pluck(:monthly_registrations)).to all be nil

          expect(described_class
            .find_by(facility_id: facility.id, month_date: month_2020_07)
            .monthly_registrations).to eq 2

          expect(described_class
            .where(facility_id: facility.id)
            .where("month_date > ?", month_2020_07)
            .where("month_date < ?", month_2021_04)
            .pluck(:monthly_registrations)).to all eq 0

          expect(described_class
            .find_by(facility_id: facility.id, month_date: month_2021_04)
            .monthly_registrations).to eq 3
        end
      end
    end
  end

  context "assigned patients by care states" do
    describe "under_care, lost_to_follow_up, dead" do
      it "computes the number of assigned patients correctly with each care state" do
        facility = create(:facility)
        _without_htn_patient = create(:patient, :without_hypertension, recorded_at: june_2021[:long_ago], assigned_facility: facility)
        ltfu_patient = create(:patient, recorded_at: june_2021[:over_12_months_ago], assigned_facility: facility)
        create(:blood_pressure, patient: ltfu_patient, recorded_at: june_2021[:over_12_months_ago])
        _under_care_patients = create_list(:patient, 2, recorded_at: june_2021[:under_12_months_ago], assigned_facility: facility)
        _different_facility_patient = create(:patient, recorded_at: june_2021[:long_ago])
        create_list(:patient, 3, recorded_at: june_2021[:long_ago], assigned_facility: facility, status: "dead")

        RefreshReportingViews.new.refresh_v2
        with_reporting_time_zone do
          expect(described_class.find_by(month_date: june_2021[:now], facility: facility).lost_to_follow_up).to eq 1
          expect(described_class.find_by(month_date: june_2021[:now], facility: facility).under_care).to eq 2
          expect(described_class.find_by(month_date: june_2021[:now], facility: facility).dead).to eq 3
        end
      end
    end

    describe "cumulative_assigned_patients" do
      it "computes the total number of assigned patients as of the given month" do
        facility = create(:facility)
        create(:patient, assigned_facility: facility, recorded_at: june_2021[:now] - 2.years)
        create(:patient, assigned_facility: facility, recorded_at: june_2021[:under_12_months_ago])
        create(:patient, assigned_facility: facility, recorded_at: june_2021[:under_3_months_ago])
        create(:patient, assigned_facility: facility, recorded_at: june_2021[:end_of_month])
        create_list(:patient, 3, recorded_at: june_2021[:long_ago], assigned_facility: facility, status: "dead")

        RefreshReportingViews.new.refresh_v2
        with_reporting_time_zone do
          expect(described_class.find_by(facility: facility, month_date: june_2021[:now] - 2.years).cumulative_assigned_patients).to eq 1
          expect(described_class.find_by(facility: facility, month_date: june_2021[:under_12_months_ago]).cumulative_assigned_patients).to eq 2
          expect(described_class.find_by(facility: facility, month_date: june_2021[:under_3_months_ago]).cumulative_assigned_patients).to eq 3
          expect(described_class.find_by(facility: facility, month_date: june_2021[:now]).cumulative_assigned_patients).to eq 4
        end
      end
    end
  end

  context "treatment outcomes in the last 3 months" do
    it "computes totals for under care patients" do
      facility = create(:facility)

      patients_controlled = create_list(:patient, 2, assigned_facility: facility, recorded_at: june_2021[:long_ago])
      patients_controlled.each do |patient|
        create(:bp_with_encounter, :under_control, patient: patient, recorded_at: june_2021[:now] - 1.month)
      end

      patients_uncontrolled = create_list(:patient, 3, assigned_facility: facility, recorded_at: june_2021[:long_ago])
      patients_uncontrolled.each do |patient|
        create(:bp_with_encounter, :hypertensive, patient: patient, recorded_at: june_2021[:now] - 1.months)
      end

      patients_missed_visit = create_list(:patient, 4, assigned_facility: facility, recorded_at: june_2021[:long_ago])
      patients_missed_visit.each do |patient|
        create(:bp_with_encounter, patient: patient, recorded_at: june_2021[:over_3_months_ago])
      end

      _patient_no_visit = create(:patient, assigned_facility: facility, recorded_at: june_2021[:long_ago])

      patients_visited_no_bp = create_list(:patient, 2, assigned_facility: facility, recorded_at: june_2021[:long_ago])
      patients_visited_no_bp.each do |patient|
        create(:prescription_drug,
          device_created_at: june_2021[:now] - 1.month,
          facility: facility,
          patient: patient,
          user: patient.registration_user)
        create(:blood_pressure, patient: patient, recorded_at: june_2021[:over_3_months_ago])
      end

      RefreshReportingViews.new.refresh_v2
      with_reporting_time_zone do
        facility_state_june_2021 = described_class.find_by(facility: facility, month_date: june_2021[:now])

        expect(facility_state_june_2021.adjusted_controlled_under_care).to eq 2
        expect(facility_state_june_2021.adjusted_uncontrolled_under_care).to eq 3
        expect(facility_state_june_2021.adjusted_missed_visit_under_care).to eq 4
        expect(facility_state_june_2021.adjusted_visited_no_bp_under_care).to eq 2
        expect(facility_state_june_2021.adjusted_patients_under_care).to eq 11
        expect(facility_state_june_2021.adjusted_patients_lost_to_follow_up).to eq 1
      end
    end

    it "computes totals for patients lost to follow up" do
      facility = create(:facility)

      _patient_no_visit = create(:patient, assigned_facility: facility, recorded_at: june_2021[:long_ago])

      patient_missed_visit = create(:patient, assigned_facility: facility, recorded_at: june_2021[:long_ago])
      create(:bp_with_encounter, patient: patient_missed_visit, recorded_at: june_2021[:over_12_months_ago])

      patient_visited_no_bp = create(:patient, assigned_facility: facility, recorded_at: june_2021[:long_ago])
      create(:prescription_drug,
        device_created_at: june_2021[:now] - 1.month,
        facility: facility,
        patient: patient_visited_no_bp,
        user: patient_visited_no_bp.registration_user)
      create(:blood_pressure, patient: patient_visited_no_bp, recorded_at: june_2021[:over_12_months_ago])

      RefreshReportingViews.new.refresh_v2
      with_reporting_time_zone do
        facility_state_june_2021 = described_class.find_by(facility: facility, month_date: june_2021[:now])

        expect(facility_state_june_2021.adjusted_missed_visit_lost_to_follow_up).to eq 2
        expect(facility_state_june_2021.adjusted_visited_no_bp_lost_to_follow_up).to eq 1
        expect(facility_state_june_2021.adjusted_patients_under_care).to eq 0
        expect(facility_state_june_2021.adjusted_patients_lost_to_follow_up).to eq 3
      end
    end
  end

  context "monthly cohort outcomes" do
    it "computes totals for under care patients" do
      facility = create(:facility)

      patients_controlled = create_list(:patient, 2, assigned_facility: facility, recorded_at: june_2021[:under_3_months_ago])
      patients_controlled.each do |patient|
        create(:bp_with_encounter, :under_control, patient: patient, recorded_at: june_2021[:now] - 1.month)
      end

      patients_uncontrolled = create_list(:patient, 3, assigned_facility: facility, recorded_at: june_2021[:under_3_months_ago])
      patients_uncontrolled.each do |patient|
        create(:bp_with_encounter, :hypertensive, patient: patient, recorded_at: june_2021[:now] - 1.months)
      end

      patients_missed_visit = create_list(:patient, 4, assigned_facility: facility, recorded_at: june_2021[:under_3_months_ago])
      patients_missed_visit.each do |patient|
        create(:bp_with_encounter, patient: patient, recorded_at: june_2021[:over_3_months_ago])
      end

      _patient_no_visit = create(:patient, assigned_facility: facility, recorded_at: june_2021[:under_3_months_ago])

      patients_visited_no_bp = create_list(:patient, 2, assigned_facility: facility, recorded_at: june_2021[:under_3_months_ago])
      patients_visited_no_bp.each do |patient|
        create(:prescription_drug,
          device_created_at: june_2021[:now] - 1.month,
          facility: facility,
          patient: patient,
          user: patient.registration_user)
        create(:blood_pressure, patient: patient, recorded_at: june_2021[:over_3_months_ago])
      end

      RefreshReportingViews.new.refresh_v2
      with_reporting_time_zone do
        facility_state_june_2021 = described_class.find_by(facility: facility, month_date: june_2021[:now])

        expect(facility_state_june_2021.monthly_cohort_controlled).to eq 2
        expect(facility_state_june_2021.monthly_cohort_uncontrolled).to eq 3
        expect(facility_state_june_2021.monthly_cohort_missed_visit).to eq 5
        expect(facility_state_june_2021.monthly_cohort_visited_no_bp).to eq 2
        expect(facility_state_june_2021.monthly_cohort_patients).to eq 12
      end
    end
  end

  context "medication dispensed in last 3 months" do
    it "counts the latest appointments scheduled per patient by days scheduled by bucket" do
      Timecop.return do
        facility = create(:facility)
        patient_1 = create(:patient, assigned_facility: facility)
        patient_2 = create(:patient, assigned_facility: facility)
        _appointment_schdeuled_after_10_days = create(:appointment, facility: facility, patient: patient_1, scheduled_date: 10.days.from_now, device_created_at: Date.today)
        _appointment_schdeuled_after_20_days = create(:appointment, facility: facility, patient: patient_2, scheduled_date: 20.days.from_now, device_created_at: Date.today)
        _appointment_schdeuled_after_31_days = create(:appointment, facility: facility, patient: patient_1, scheduled_date: Date.today, device_created_at: 1.month.ago)
        _appointment_schdeuled_after_61_days = create(:appointment, facility: facility, patient: patient_1, scheduled_date: Date.today, device_created_at: 2.month.ago)

        RefreshReportingViews.new.refresh_v2

        expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_0_to_14_days).to eq 1
        expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_15_to_30_days).to eq 1
        expect(described_class.find_by(month_date: Period.month(1.month.ago), facility: facility).appts_scheduled_31_to_60_days).to eq 1
        expect(described_class.find_by(month_date: Period.month(2.month.ago), facility: facility).appts_scheduled_more_than_60_days).to eq 1
      end
    end

    it "totals the latest appointments scheduled per patient in a month" do
      Timecop.return do
        facility = create(:facility)
        patient = create(:patient, assigned_facility: facility)
        today = Time.current.beginning_of_month.to_date
        _appointment_created_today = create(:appointment, facility: facility, patient: patient, scheduled_date: today + 10.days, device_created_at: today)
        _appointment_created_tomorrow = create(:appointment, facility: facility, patient: patient, scheduled_date: today + 20.days, device_created_at: today.next_day)
        _appointment_created_day_after_tomorrow = create(:appointment, facility: facility, patient: patient, scheduled_date: today + 30.days, device_created_at: today.next_day.next_day)

        RefreshReportingViews.new.refresh_v2

        expect(described_class.find_by(month_date: Period.current, facility: facility).total_appts_scheduled).to eq 1
      end
    end
  end
end
