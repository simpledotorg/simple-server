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
        RefreshReportingViews.refresh_v2
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

        RefreshReportingViews.refresh_v2
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

        RefreshReportingViews.refresh_v2
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

        RefreshReportingViews.refresh_v2
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

      RefreshReportingViews.refresh_v2
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

      RefreshReportingViews.refresh_v2
      with_reporting_time_zone do
        facility_state_june_2021 = described_class.find_by(facility: facility, month_date: june_2021[:now])

        expect(facility_state_june_2021.adjusted_missed_visit_lost_to_follow_up).to eq 2
        expect(facility_state_june_2021.adjusted_visited_no_bp_lost_to_follow_up).to eq 0
        expect(facility_state_june_2021.adjusted_patients_under_care).to eq 1
        expect(facility_state_june_2021.adjusted_patients_lost_to_follow_up).to eq 2
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

      RefreshReportingViews.refresh_v2
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
        Timecop.freeze("#{Date.today.end_of_month} 23:00 IST") do
          facility = create(:facility)
          patients = create_list(:patient, 2, recorded_at: 3.months.ago, assigned_facility: facility)
          _current_month_appointments = patients.each do |patient|
            create(:appointment, facility: facility, patient: patient, scheduled_date: 10.days.from_now, device_created_at: Time.current)
          end

          _appointment_1_month_ago = create(:appointment,
            facility: facility,
            patient: patients.first,
            scheduled_date: Date.today,
            device_created_at: 32.days.ago)
          _appointment_2_month_ago = create(:appointment,
            facility: facility,
            patient: patients.first,
            scheduled_date: Date.today,
            device_created_at: 63.days.ago)

          RefreshReportingViews.refresh_v2

          expect(described_class.find_by(month_date: Period.current, facility: facility).appts_scheduled_0_to_14_days).to eq 2
          expect(described_class.find_by(month_date: Period.current, facility: facility).total_appts_scheduled).to eq 2
          expect(described_class.find_by(month_date: Period.month(32.days.ago), facility: facility).appts_scheduled_32_to_62_days).to eq 1
          expect(described_class.find_by(month_date: Period.month(63.days.ago), facility: facility).appts_scheduled_more_than_62_days).to eq 1
        end
      end
    end
  end

  context "Diabetes" do
    context "registraions" do
      describe "cumulative_diabetes_registrations" do
        it "has the total number of diabetic registrations since the starting of time for every facility upto a given month" do
          facility = create(:facility)
          old_diabetes_patients = create_list(:patient, 2, :diabetes, registration_facility: facility, recorded_at: june_2021[:long_ago])
          new_diabetic_patients = create_list(:patient, 3, :diabetes, registration_facility: facility, recorded_at: june_2021[:two_months_ago])
          _non_diabetic_patients = create_list(:patient, 3, :without_diabetes, registration_facility: facility, recorded_at: june_2021[:two_months_ago])

          refresh_views
          with_reporting_time_zone do
            expect(described_class
                     .where(facility_id: facility.id)
                     .where("month_date < ?", june_2021[:long_ago])
                     .pluck(:cumulative_diabetes_registrations)).to all eq 0

            expect(described_class
                     .where(facility_id: facility.id)
                     .where("month_date >= ?", june_2021[:long_ago])
                     .where("month_date < ?", june_2021[:two_months_ago])
                     .pluck(:cumulative_diabetes_registrations)).to all eq old_diabetes_patients.size

            expect(described_class
                     .where(facility_id: facility.id)
                     .where("month_date >= ?", june_2021[:two_months_ago])
                     .pluck(:cumulative_diabetes_registrations)).to all eq (old_diabetes_patients + new_diabetic_patients).size
          end
        end

        it "does not count patients which have not been marked as diabetic" do
          facility = create(:facility)
          _non_diabetic_patients = create_list(:patient, 3, :without_diabetes, registration_facility: facility, recorded_at: june_2021[:two_months_ago])

          refresh_views
          with_reporting_time_zone do
            expect(described_class
                     .where(facility_id: facility.id)
                     .pluck(:cumulative_diabetes_registrations)).to all be_nil
          end
        end
      end

      describe "monthly_diabetes_registrations" do
        it "has the number of diabetes patients registered in a given month" do
          facility = create(:facility)
          old_diabetes_patients = create_list(:patient, 2, :diabetes, registration_facility: facility, recorded_at: june_2021[:under_12_months_ago])
          new_diabetic_patients = create_list(:patient, 3, :diabetes, registration_facility: facility, recorded_at: june_2021[:two_months_ago])
          _non_diabetic_patients = create_list(:patient, 3, :without_diabetes, registration_facility: facility, recorded_at: june_2021[:two_months_ago])

          month_2020_07 = "2020-07-01"
          month_2021_04 = "2021-04-01"

          refresh_views
          with_reporting_time_zone do
            expect(described_class
                     .where(facility_id: facility.id)
                     .where("month_date < ?", month_2020_07)
                     .pluck(:monthly_diabetes_registrations)).to all be_nil

            expect(
              described_class
                .where(facility_id: facility.id)
                .where(month_date: month_2020_07)
                .pluck(:monthly_diabetes_registrations)
            ).to eq [old_diabetes_patients.size]

            expect(
              described_class
                .where(facility_id: facility.id)
                .where("month_date > ?", month_2020_07)
                .where("month_date < ?", month_2021_04)
                .pluck(:monthly_diabetes_registrations)
            ).to all eq 0

            expect(
              described_class
                .where(facility_id: facility.id)
                .where(month_date: month_2021_04)
                .pluck(:monthly_diabetes_registrations)
            ).to eq [new_diabetic_patients.size]
          end
        end

        it "does not count patients who have not been marked as diabetic" do
          facility = create(:facility)
          _non_diabetic_patients = create_list(:patient, 3, :without_diabetes, registration_facility: facility, recorded_at: june_2021[:two_months_ago])

          refresh_views
          with_reporting_time_zone do
            expect(described_class
                     .where(facility_id: facility.id)
                     .pluck(:monthly_diabetes_registrations)).to all be_nil
          end
        end
      end
    end

    context "assigned patients by care states" do
      describe "under care, lost to follow up and dead patients" do
        it "has the number of assigned diabetic patients which are under care, lost to follow up or dead" do
          facility = create(:facility)

          # non diabetic patient
          _non_diabetic_patient = create(:patient, :without_diabetes, assigned_facility: facility)

          # ltfu diabetes patient
          ltfu_diabetic_patients = create_list(:patient, 2, :diabetes, assigned_facility: facility, recorded_at: june_2021[:over_12_months_ago])
          create(:blood_sugar, :with_encounter, patient: ltfu_diabetic_patients.first, recorded_at: june_2021[:over_12_months_ago])

          # under care diabetes patients
          under_care_diabetic_patients = create_list(:patient, 3, :diabetes, assigned_facility: facility, recorded_at: june_2021[:over_12_months_ago])
          create(:blood_sugar, :with_encounter, patient: under_care_diabetic_patients.first, recorded_at: june_2021[:one_month_ago])
          create(:blood_pressure, :with_encounter, patient: under_care_diabetic_patients.second, recorded_at: june_2021[:one_month_ago])
          create(:appointment, patient: under_care_diabetic_patients.third, recorded_at: june_2021[:one_month_ago])

          # dead patients
          dead_diabetic_patients = create_list(:patient, 4, :diabetes, status: "dead", assigned_facility: facility, recorded_at: june_2021[:under_3_months_ago])

          refresh_views
          with_reporting_time_zone do
            expect(described_class
                     .where(facility: facility, month_date: june_2021[:now])
                     .pluck(:diabetes_under_care, :diabetes_lost_to_follow_up, :diabetes_dead).first)
              .to eq([under_care_diabetic_patients.count, ltfu_diabetic_patients.count, dead_diabetic_patients.count])
          end
        end

        it "does not count patients which are marked as non diabetic" do
          facility = create(:facility)

          # non diabetic patient
          _non_diabetic_patient = create(:patient, :without_diabetes, assigned_facility: facility)

          # ltfu diabetes patient
          ltfu_non_diabetic_patients = create_list(:patient, 2, :without_diabetes, assigned_facility: facility, recorded_at: june_2021[:over_12_months_ago])
          create(:blood_sugar, :with_encounter, patient: ltfu_non_diabetic_patients.first, recorded_at: june_2021[:over_12_months_ago])

          # under care diabetes patients
          under_care_non_diabetic_patients = create_list(:patient, 3, :without_diabetes, assigned_facility: facility, recorded_at: june_2021[:over_12_months_ago])
          create(:blood_sugar, :with_encounter, patient: under_care_non_diabetic_patients.first, recorded_at: june_2021[:one_month_ago])
          create(:blood_pressure, :with_encounter, patient: under_care_non_diabetic_patients.second, recorded_at: june_2021[:one_month_ago])
          create(:appointment, patient: under_care_non_diabetic_patients.third, recorded_at: june_2021[:one_month_ago])

          # dead patients
          _dead_non_diabetic_patients = create_list(:patient, 3, :without_diabetes, status: "dead", assigned_facility: facility, recorded_at: june_2021[:under_3_months_ago])

          refresh_views
          with_reporting_time_zone do
            expect(described_class
                     .where(facility: facility, month_date: june_2021[:now])
                     .pluck(:diabetes_under_care, :diabetes_lost_to_follow_up, :diabetes_dead).first)
              .to all be_nil
          end
        end
      end

      describe "cumulative_assigned_diabetes_patients" do
        it "has the cumulative count of a facilities assigned diabetic patients as of a give month" do
          facility = create(:facility)
          create(:patient, :diabetes, assigned_facility: facility, recorded_at: june_2021[:now] - 2.years)
          create(:patient, :diabetes, assigned_facility: facility, recorded_at: june_2021[:under_12_months_ago])
          create(:patient, :diabetes, assigned_facility: facility, recorded_at: june_2021[:under_3_months_ago])
          create(:patient, :diabetes, assigned_facility: facility, recorded_at: june_2021[:end_of_month])
          create_list(:patient, 3, :diabetes, recorded_at: june_2021[:long_ago], assigned_facility: facility, status: "dead")

          RefreshReportingViews.refresh_v2
          with_reporting_time_zone do
            expect(described_class.find_by(facility: facility, month_date: june_2021[:now] - 2.years).cumulative_assigned_diabetic_patients).to eq 1
            expect(described_class.find_by(facility: facility, month_date: june_2021[:under_12_months_ago]).cumulative_assigned_diabetic_patients).to eq 2
            expect(described_class.find_by(facility: facility, month_date: june_2021[:under_3_months_ago]).cumulative_assigned_diabetic_patients).to eq 3
            expect(described_class.find_by(facility: facility, month_date: june_2021[:now]).cumulative_assigned_diabetic_patients).to eq 4
          end
        end

        it "does not count non diabetic patients" do
          facility = create(:facility)
          create(:patient, :without_diabetes, assigned_facility: facility, recorded_at: june_2021[:now] - 2.years)
          create(:patient, :without_diabetes, assigned_facility: facility, recorded_at: june_2021[:under_12_months_ago])
          create(:patient, :without_diabetes, assigned_facility: facility, recorded_at: june_2021[:under_3_months_ago])
          create(:patient, :without_diabetes, assigned_facility: facility, recorded_at: june_2021[:end_of_month])
          create_list(:patient, 3, :without_diabetes, recorded_at: june_2021[:long_ago], assigned_facility: facility, status: "dead")

          RefreshReportingViews.refresh_v2
          with_reporting_time_zone do
            expect(described_class.find_by(facility: facility, month_date: june_2021[:now] - 2.years).cumulative_assigned_diabetic_patients).to be_nil
            expect(described_class.find_by(facility: facility, month_date: june_2021[:under_12_months_ago]).cumulative_assigned_diabetic_patients).to be_nil
            expect(described_class.find_by(facility: facility, month_date: june_2021[:under_3_months_ago]).cumulative_assigned_diabetic_patients).to be_nil
            expect(described_class.find_by(facility: facility, month_date: june_2021[:now]).cumulative_assigned_diabetic_patients).to be_nil
          end
        end
      end
    end

    context "treatment outcomes in last 3 months" do
      it "contains number of total under care patients at a facility, broken down by the blood sugar type and risk state" do
        facility = create(:facility)
        [:random, :post_prandial, :fasting, :hba1c].each do |blood_sugar_type|
          create_list(:patient, 1, :diabetes, assigned_facility: facility, recorded_at: june_2021[:long_ago]).each do |patient|
            create(:blood_sugar, :with_encounter, :bs_below_200, blood_sugar_type: blood_sugar_type, patient: patient, recorded_at: june_2021[:under_3_months_ago])
          end
        end

        [:random, :post_prandial, :fasting, :hba1c].each do |blood_sugar_type|
          create_list(:patient, 2, :diabetes, assigned_facility: facility, recorded_at: june_2021[:long_ago]).each do |patient|
            create(:blood_sugar, :with_encounter, :bs_200_to_300, blood_sugar_type: blood_sugar_type, patient: patient, recorded_at: june_2021[:under_3_months_ago])
          end
        end

        [:random, :post_prandial, :fasting, :hba1c].each do |blood_sugar_type|
          create_list(:patient, 2, :diabetes, assigned_facility: facility, recorded_at: june_2021[:long_ago]).each do |patient|
            create(:blood_sugar, :with_encounter, :bs_over_300, blood_sugar_type: blood_sugar_type, patient: patient, recorded_at: june_2021[:under_3_months_ago])
          end
        end

        refresh_views
        results = described_class.find_by(facility: facility, month_date: june_2021[:now])
        expect(results.adjusted_random_bs_below_200_under_care).to eq 1
        expect(results.adjusted_post_prandial_bs_below_200_under_care).to eq 1
        expect(results.adjusted_fasting_bs_below_200_under_care).to eq 1
        expect(results.adjusted_hba1c_bs_below_200_under_care).to eq 1
        expect(results.adjusted_bs_below_200_under_care).to eq 4

        expect(results.adjusted_random_bs_200_to_300_under_care).to eq 2
        expect(results.adjusted_post_prandial_bs_200_to_300_under_care).to eq 2
        expect(results.adjusted_fasting_bs_200_to_300_under_care).to eq 2
        expect(results.adjusted_hba1c_bs_200_to_300_under_care).to eq 2
        expect(results.adjusted_bs_200_to_300_under_care).to eq 8

        expect(results.adjusted_random_bs_over_300_under_care).to eq 2
        expect(results.adjusted_post_prandial_bs_over_300_under_care).to eq 2
        expect(results.adjusted_fasting_bs_over_300_under_care).to eq 2
        expect(results.adjusted_hba1c_bs_over_300_under_care).to eq 2
        expect(results.adjusted_bs_over_300_under_care).to eq 8

        expect(results.adjusted_diabetes_patients_under_care).to eq 20
      end

      it "contains number of total lost to follow up patients at a facility, broken down by the blood sugar type and risk state" do
        facility = create(:facility)
        create_list(:patient, 5, :diabetes, assigned_facility: facility, recorded_at: june_2021[:long_ago]).each do |patient|
          create(:blood_sugar, :with_encounter, patient: patient, facility: facility, recorded_at: june_2021[:over_12_months_ago])
        end
        refresh_views
        results = described_class.find_by(facility: facility, month_date: june_2021[:now])
        expect(results.adjusted_diabetes_patients_lost_to_follow_up).to eq 5
      end

      it "contains number of total missed visits patients at a facility" do
        facility = create(:facility)
        create_list(:patient, 2, :diabetes, assigned_facility: facility, recorded_at: june_2021[:long_ago]).each do |patient|
          create(:blood_sugar, :with_encounter, patient: patient, recorded_at: june_2021[:four_months_ago])
        end

        create_list(:patient, 3, :diabetes, assigned_facility: facility, recorded_at: june_2021[:long_ago]).each do |patient|
          create(:blood_sugar, :with_encounter, patient: patient, recorded_at: june_2021[:over_12_months_ago])
        end

        refresh_views
        results = described_class.find_by(facility: facility, month_date: june_2021[:now])
        expect(results.adjusted_bs_missed_visit_under_care).to eq 2
        expect(results.adjusted_bs_missed_visit_lost_to_follow_up).to eq 3
      end

      it "contains number of total visited but no BS measured patients at a facility" do
        facility = create(:facility)
        create_list(:patient, 2, :diabetes, assigned_facility: facility, recorded_at: june_2021[:long_ago]).each do |patient|
          create(:blood_pressure, :with_encounter, patient: patient, recorded_at: june_2021[:under_3_months_ago])
        end

        refresh_views
        results = described_class.find_by(facility: facility, month_date: june_2021[:now])
        expect(results.adjusted_visited_no_bs_under_care).to eq 2
      end
    end

    it "contains the number of monthly diabetes followup patients" do
      facility = create(:facility)
      patients = create_list(:patient, 2, :diabetes, assigned_facility: facility, recorded_at: june_2021[:long_ago])
      create(:blood_sugar, :with_encounter, :bs_below_200, blood_sugar_type: :random, patient: patients.first, recorded_at: june_2021[:two_months_ago])
      create(:blood_pressure, :with_encounter, patient: patients.second, recorded_at: june_2021[:one_month_ago])

      refresh_views
      with_reporting_time_zone do
        expect(described_class
                 .where(facility_id: facility.id)
                 .where("month_date = ?", june_2021[:two_months_ago])
                 .pluck(:monthly_diabetes_follow_ups)).to all eq 1
        expect(described_class
                 .where(facility_id: facility.id)
                 .where("month_date = ?", june_2021[:one_month_ago])
                 .pluck(:monthly_diabetes_follow_ups)).to all eq 1
      end
    end
  end

  describe ".with_patients" do
    it "returns all rows where a facility has registered patients" do
      facility_1 = create(:facility)
      facility_2 = create(:facility)

      create(:patient, registration_facility: facility_1)
      create(:patient, registration_facility: facility_1, device_created_at: 3.months.ago)

      refresh_views
      rows = Reports::FacilityState.with_patients
      expect(rows.pluck(:facility_id, :month_date, :cumulative_registrations))
        .to include([facility_1.id, 3.months.ago.at_beginning_of_month, 1],
          [facility_1.id, 2.months.ago.at_beginning_of_month, 1],
          [facility_1.id, 1.months.ago.at_beginning_of_month, 1],
          [facility_1.id, Date.today.at_beginning_of_month, 2])
      expect(rows.pluck(:facility_id, :month_date))
        .not_to include([facility_1.id, 4.months.ago.at_beginning_of_month])
      expect(rows.pluck(:facility_id)).not_to include(facility_2.id)
    end

    it "returns all rows where a facility has assigned patients" do
      facility_1 = create(:facility)
      facility_2 = create(:facility)

      create(:patient, assigned_facility: facility_1)
      create(:patient, assigned_facility: facility_1, device_created_at: 3.months.ago)

      refresh_views
      rows = Reports::FacilityState.with_patients
      expect(rows.pluck(:facility_id, :month_date, :cumulative_assigned_patients))
        .to include([facility_1.id, 3.months.ago.at_beginning_of_month, 1],
          [facility_1.id, 2.months.ago.at_beginning_of_month, 1],
          [facility_1.id, 1.months.ago.at_beginning_of_month, 1],
          [facility_1.id, Date.today.at_beginning_of_month, 2])
      expect(rows.pluck(:facility_id, :month_date))
        .not_to include([facility_1.id, 4.months.ago.at_beginning_of_month])
      expect(rows.pluck(:facility_id)).not_to include(facility_2.id)
    end

    it "returns all rows where a facility has monthly follow patients" do
      facility_1 = create(:facility)
      facility_2 = create(:facility)

      patient = create(:patient, :hypertension, recorded_at: 6.months.ago)
      create(:blood_pressure, patient: patient, facility: facility_1)
      create(:blood_pressure, patient: patient, facility: facility_1, device_created_at: 3.months.ago)

      refresh_views
      rows = Reports::FacilityState.with_patients
      expect(rows.pluck(:facility_id, :month_date, :monthly_follow_ups))
        .to include([facility_1.id, 3.months.ago.at_beginning_of_month, 1],
          [facility_1.id, Date.today.at_beginning_of_month, 1])
      expect(rows.pluck(:facility_id, :month_date))
        .not_to include([facility_1.id, 2.months.ago.at_beginning_of_month],
          [facility_1.id, 1.months.ago.at_beginning_of_month])
      expect(rows.pluck(:facility_id)).not_to include(facility_2.id)
    end
  end
end
