require "rails_helper"

RSpec.describe Reports::PatientState, {type: :model, reporting_spec: true} do
  describe "Associations" do
    it { should belong_to(:patient) }
  end

  around do |example|
    freeze_time_for_reporting_specs(example)
  end

  it "does not include deleted patients" do
    create(:patient)
    deleted_patient = create(:patient, deleted_at: june_2021[:over_3_months_ago])
    described_class.refresh
    with_reporting_time_zone do
      expect(described_class.count).not_to eq 0
      expect(described_class.where(patient_id: deleted_patient.id)).to be_empty
    end
  end

  context "indicators" do
    describe "current_age" do
      it "determines the current age of the patient given their age, age_updated_at" do
        patient = create(:patient, age: 58, recorded_at: 2.years.ago, age_updated_at: 2.years.ago)
        described_class.refresh
        with_reporting_time_zone do
          expect(described_class.where(patient_id: patient.id).pluck(:current_age)).to all eq(60)
        end
      end

      it "determines the current age of the patient given their dob, and prefers it even when age is present" do
        patient = create(:patient, date_of_birth: 80.years.ago, age: 58, recorded_at: 2.years.ago, age_updated_at: 2.years.ago)
        described_class.refresh
        with_reporting_time_zone do
          expect(described_class.where(patient_id: patient.id).pluck(:current_age)).to all eq(80)
        end
      end
    end

    describe "htn_care_state" do
      it "marks a dead patient dead" do
        dead_patient = create(:patient, status: :dead)
        described_class.refresh
        with_reporting_time_zone do
          expect(described_class.where(htn_care_state: "dead").pluck(:patient_id)).to include(dead_patient.id)
        end
      end

      it "marks a patient registered more than 12 months ago with BP more than 12 months ago as ltfu" do
        patient_registered_13m_ago = Timecop.freeze(13.months.ago) { create(:patient) }
        Timecop.freeze(13.months.ago) { create(:blood_pressure, patient: patient_registered_13m_ago) }

        RefreshReportingViews.refresh_v2
        with_reporting_time_zone do
          expect(described_class
            .where(htn_care_state: "lost_to_follow_up", month_date: Date.current.beginning_of_month)
            .pluck(:patient_id)).to include(patient_registered_13m_ago.id)
          expect(described_class
            .where(htn_care_state: "under_care", month_date: Date.current.beginning_of_month)
            .pluck(:patient_id)).not_to include(patient_registered_13m_ago.id)
        end
      end

      it "marks a patient with no bp as lost to follow up depending on registration date" do
        patient_registered_12m_ago = Timecop.freeze(12.months.ago) { create(:patient) }
        patient_registered_11m_ago = Timecop.freeze(11.months.ago) { create(:patient) }

        RefreshReportingViews.refresh_v2
        with_reporting_time_zone do
          expect(described_class
            .where(htn_care_state: "lost_to_follow_up", month_date: Date.current.beginning_of_month)
            .pluck(:patient_id)).to include(patient_registered_12m_ago.id)
          expect(described_class
            .where(htn_care_state: "under_care", month_date: Date.current.beginning_of_month)
            .pluck(:patient_id)).not_to include(patient_registered_12m_ago.id)

          expect(described_class
            .where(htn_care_state: "lost_to_follow_up", month_date: Date.current.beginning_of_month)
            .pluck(:patient_id)).not_to include(patient_registered_11m_ago.id)
          expect(described_class
            .where(htn_care_state: "under_care", month_date: Date.current.beginning_of_month)
            .pluck(:patient_id)).to include(patient_registered_11m_ago.id)
        end
      end

      it "marks a patient registered long ago, with a recent BP as under care" do
        patient_with_recent_bp = Timecop.freeze(13.months.ago) { create(:patient) }
        Timecop.freeze(11.months.ago) { create(:blood_pressure, :with_encounter, patient: patient_with_recent_bp) }

        RefreshReportingViews.refresh_v2
        with_reporting_time_zone do
          expect(described_class
            .where(htn_care_state: "lost_to_follow_up", month_date: Date.current.beginning_of_month)
            .pluck(:patient_id)).not_to include(patient_with_recent_bp.id)
          expect(described_class
            .where(htn_care_state: "under_care", month_date: Date.current.beginning_of_month)
            .pluck(:patient_id)).to include(patient_with_recent_bp.id)
        end
      end

      context "ltfu tests ported from patient_spec.rb" do
        it "picks up the beginning interval of ltfu for 12 months ago correctly" do
          under_care_patient = create(:patient, recorded_at: june_2021[:long_ago])
          ltfu_patient = create(:patient, recorded_at: june_2021[:long_ago])

          create(:blood_pressure, :with_encounter, patient: under_care_patient, recorded_at: june_2021[:under_12_months_ago])
          create(:blood_pressure, :with_encounter, patient: ltfu_patient, recorded_at: june_2021[:over_12_months_ago])

          RefreshReportingViews.refresh_v2

          with_reporting_time_zone do
            expect(described_class
              .where(htn_care_state: "lost_to_follow_up", month_date: june_2021[:beginning_of_month])
              .pluck(:patient_id)).to include(ltfu_patient.id)
            expect(described_class
              .where(htn_care_state: "lost_to_follow_up", month_date: june_2021[:beginning_of_month])
              .pluck(:patient_id)).not_to include(under_care_patient.id)
            expect(described_class
              .where(htn_care_state: "under_care", month_date: june_2021[:beginning_of_month])
              .pluck(:patient_id)).to include(under_care_patient.id)
            expect(described_class
              .where(htn_care_state: "under_care", month_date: june_2021[:beginning_of_month])
              .pluck(:patient_id)).not_to include(ltfu_patient.id)
          end
        end

        it "picks up the ending interval of ltfu for now correctly" do
          under_care_patient = create(:patient, recorded_at: june_2021[:long_ago])
          ltfu_patient = create(:patient, recorded_at: june_2021[:long_ago])

          create(:blood_pressure, :with_encounter, patient: under_care_patient, recorded_at: june_2021[:end_of_month] - 1.minute)
          create(:blood_pressure, :with_encounter, patient: ltfu_patient, recorded_at: june_2021[:end_of_month] + 1.minute)

          RefreshReportingViews.refresh_v2

          with_reporting_time_zone do
            expect(described_class
              .where(htn_care_state: "lost_to_follow_up", month_date: june_2021[:beginning_of_month])
              .pluck(:patient_id)).not_to include(under_care_patient.id)
            expect(described_class
              .where(htn_care_state: "lost_to_follow_up", month_date: june_2021[:beginning_of_month])
              .pluck(:patient_id)).to include(ltfu_patient.id)
            expect(described_class
              .where(htn_care_state: "under_care", month_date: june_2021[:beginning_of_month])
              .pluck(:patient_id)).not_to include(ltfu_patient.id)
            expect(described_class
              .where(htn_care_state: "under_care", month_date: june_2021[:beginning_of_month])
              .pluck(:patient_id)).to include(under_care_patient.id)
          end
        end

        it "registration cutoffs for a year ago" do
          under_care_patient = create(:patient, recorded_at: june_2021[:under_12_months_ago])
          ltfu_patient = create(:patient, recorded_at: june_2021[:over_12_months_ago])

          RefreshReportingViews.refresh_v2
          with_reporting_time_zone do
            expect(described_class
              .where(htn_care_state: "lost_to_follow_up", month_date: june_2021[:beginning_of_month])
              .pluck(:patient_id)).not_to include(under_care_patient.id)
            expect(described_class
              .where(htn_care_state: "lost_to_follow_up", month_date: june_2021[:beginning_of_month])
              .pluck(:patient_id)).to include(ltfu_patient.id)
            expect(described_class
              .where(htn_care_state: "under_care", month_date: june_2021[:beginning_of_month])
              .pluck(:patient_id)).not_to include(ltfu_patient.id)
            expect(described_class
              .where(htn_care_state: "under_care", month_date: june_2021[:beginning_of_month])
              .pluck(:patient_id)).to include(under_care_patient.id)
          end
        end
      end
    end

    describe "htn_treatment_outcome_in_last_3_months is set to" do
      it "missed_visit if the patient hasn't visited in the last 3 months" do
        patient_1 = create(:patient, recorded_at: june_2021[:long_ago])
        create(:encounter, patient: patient_1, encountered_on: june_2021[:over_3_months_ago])
        patient_2 = create(:patient, recorded_at: june_2021[:long_ago])
        create(:encounter, patient: patient_2, encountered_on: june_2021[:under_3_months_ago])
        patient_3 = create(:patient, recorded_at: june_2021[:long_ago])
        RefreshReportingViews.refresh_v2

        with_reporting_time_zone do
          expect(described_class.where(htn_treatment_outcome_in_last_3_months: "missed_visit", month_date: june_2021[:now]).pluck(:patient_id))
            .to include(patient_1.id, patient_3.id)
          expect(described_class.where(htn_treatment_outcome_in_last_3_months: "missed_visit", month_date: june_2021[:now]).pluck(:patient_id))
            .not_to include(patient_2.id)
        end
      end

      it "visited_no_bp if the patient visited, but didn't get a BP taken in the last 3 months" do
        patient_bp_over_3_months = create(:patient, recorded_at: june_2021[:long_ago])
        create(:prescription_drug,
          device_created_at: june_2021[:now] - 1.month,
          facility: patient_bp_over_3_months.registration_facility,
          patient: patient_bp_over_3_months,
          user: patient_bp_over_3_months.registration_user)
        create(:blood_pressure, patient: patient_bp_over_3_months, recorded_at: june_2021[:over_3_months_ago])

        patient_bp_under_3_months = create(:patient, recorded_at: june_2021[:long_ago])
        create(:prescription_drug,
          device_created_at: june_2021[:now] - 1.month,
          facility: patient_bp_under_3_months.registration_facility,
          patient: patient_bp_under_3_months,
          user: patient_bp_under_3_months.registration_user)
        create(:blood_pressure, patient: patient_bp_under_3_months, recorded_at: june_2021[:under_3_months_ago])

        patient_with_no_bp = create(:patient, recorded_at: june_2021[:long_ago])
        create(:prescription_drug,
          device_created_at: june_2021[:now] - 1.month,
          facility: patient_with_no_bp.registration_facility,
          patient: patient_with_no_bp,
          user: patient_with_no_bp.registration_user)
        RefreshReportingViews.refresh_v2

        with_reporting_time_zone do
          expect(described_class.where(htn_treatment_outcome_in_last_3_months: "visited_no_bp", month_date: june_2021[:now]).pluck(:patient_id))
            .to include(patient_bp_over_3_months.id, patient_with_no_bp.id)
          expect(described_class.where(htn_treatment_outcome_in_last_3_months: "visited_no_bp", month_date: june_2021[:now]).pluck(:patient_id))
            .not_to include(patient_bp_under_3_months.id)
        end
      end

      it "controlled if there is a BP measured in the last 3 months that is under control" do
        patient_controlled = create(:patient, recorded_at: june_2021[:long_ago])
        create(:bp_with_encounter, :under_control, patient: patient_controlled, recorded_at: june_2021[:now] - 1.month)

        patient_bp_over_3_months = create(:patient, recorded_at: june_2021[:long_ago])
        create(:bp_with_encounter, patient: patient_bp_over_3_months, recorded_at: june_2021[:over_3_months_ago])

        RefreshReportingViews.refresh_v2

        with_reporting_time_zone do
          expect(described_class.where(htn_treatment_outcome_in_last_3_months: "controlled", month_date: june_2021[:now]).pluck(:patient_id))
            .to include(patient_controlled.id)
          expect(described_class.where(htn_treatment_outcome_in_last_3_months: %w[uncontrolled controlled], month_date: june_2021[:now]).pluck(:patient_id))
            .not_to include(patient_bp_over_3_months.id)
        end
      end

      it "uncontrolled if there is a BP measured in the last 3 months that is under/not under control" do
        patient_uncontrolled = create(:patient, recorded_at: june_2021[:long_ago])
        create(:bp_with_encounter, :hypertensive, patient: patient_uncontrolled, recorded_at: june_2021[:now] - 1.months)

        patient_bp_over_3_months = create(:patient, recorded_at: june_2021[:long_ago])
        create(:bp_with_encounter, patient: patient_bp_over_3_months, recorded_at: june_2021[:over_3_months_ago])

        RefreshReportingViews.refresh_v2

        with_reporting_time_zone do
          expect(described_class.where(htn_treatment_outcome_in_last_3_months: "uncontrolled", month_date: june_2021[:now]).pluck(:patient_id))
            .to include(patient_uncontrolled.id)
          expect(described_class.where(htn_treatment_outcome_in_last_3_months: %w[uncontrolled controlled], month_date: june_2021[:now]).pluck(:patient_id))
            .not_to include(patient_bp_over_3_months.id)
        end
      end
    end

    describe "htn_treatment_outcome_in_last_2_months is set to" do
      it "missed_visit if the patient hasn't visited in the last 2 months" do
        patient_1 = create(:patient, recorded_at: june_2021[:long_ago])
        create(:encounter, patient: patient_1, encountered_on: june_2021[:now] - 3.months)
        patient_2 = create(:patient, recorded_at: june_2021[:long_ago])
        create(:encounter, patient: patient_2, encountered_on: june_2021[:now] - 1.month)
        patient_3 = create(:patient, recorded_at: june_2021[:long_ago])
        RefreshReportingViews.refresh_v2

        with_reporting_time_zone do
          expect(described_class.where(htn_treatment_outcome_in_last_2_months: "missed_visit", month_date: june_2021[:now]).pluck(:patient_id))
            .to include(patient_1.id, patient_3.id)
          expect(described_class.where(htn_treatment_outcome_in_last_2_months: "missed_visit", month_date: june_2021[:now]).pluck(:patient_id))
            .not_to include(patient_2.id)
        end
      end

      it "visited_no_bp if the patient visited, but didn't get a BP taken in the last 2 months" do
        patient_bp_over_2_months = create(:patient, recorded_at: june_2021[:long_ago])
        create(:prescription_drug,
          device_created_at: june_2021[:now] - 1.month,
          facility: patient_bp_over_2_months.registration_facility,
          patient: patient_bp_over_2_months,
          user: patient_bp_over_2_months.registration_user)
        create(:blood_pressure, patient: patient_bp_over_2_months, recorded_at: june_2021[:now] - 2.months)

        patient_bp_under_2_months = create(:patient, recorded_at: june_2021[:long_ago])
        create(:prescription_drug,
          device_created_at: june_2021[:now] - 1.month,
          facility: patient_bp_under_2_months.registration_facility,
          patient: patient_bp_under_2_months,
          user: patient_bp_under_2_months.registration_user)
        create(:blood_pressure, patient: patient_bp_under_2_months, recorded_at: june_2021[:now] - 1.month)

        patient_with_no_bp = create(:patient, recorded_at: june_2021[:long_ago])
        create(:prescription_drug,
          device_created_at: june_2021[:now] - 1.month,
          facility: patient_with_no_bp.registration_facility,
          patient: patient_with_no_bp,
          user: patient_with_no_bp.registration_user)
        RefreshReportingViews.refresh_v2

        with_reporting_time_zone do
          expect(described_class.where(htn_treatment_outcome_in_last_2_months: "visited_no_bp", month_date: june_2021[:now]).pluck(:patient_id))
            .to include(patient_bp_over_2_months.id, patient_with_no_bp.id)
          expect(described_class.where(htn_treatment_outcome_in_last_2_months: "visited_no_bp", month_date: june_2021[:now]).pluck(:patient_id))
            .not_to include(patient_bp_under_2_months.id)
        end
      end

      it "controlled if there is a BP measured in the last 2 months that is under control" do
        patient_controlled = create(:patient, recorded_at: june_2021[:long_ago])
        create(:bp_with_encounter, :under_control, patient: patient_controlled, recorded_at: june_2021[:now] - 1.month)

        patient_bp_over_2_months = create(:patient, recorded_at: june_2021[:long_ago])
        create(:bp_with_encounter, patient: patient_bp_over_2_months, recorded_at: june_2021[:now] - 2.months)

        RefreshReportingViews.refresh_v2

        with_reporting_time_zone do
          expect(described_class.where(htn_treatment_outcome_in_last_2_months: "controlled", month_date: june_2021[:now]).pluck(:patient_id))
            .to include(patient_controlled.id)
          expect(described_class.where(htn_treatment_outcome_in_last_2_months: %w[uncontrolled controlled], month_date: june_2021[:now]).pluck(:patient_id))
            .not_to include(patient_bp_over_2_months.id)
        end
      end

      it "uncontrolled if there is a BP measured in the last 2 months that is not under control" do
        patient_uncontrolled = create(:patient, recorded_at: june_2021[:long_ago])
        create(:bp_with_encounter, :hypertensive, patient: patient_uncontrolled, recorded_at: june_2021[:now] - 1.months)

        patient_bp_over_2_months = create(:patient, recorded_at: june_2021[:long_ago])
        create(:bp_with_encounter, patient: patient_bp_over_2_months, recorded_at: june_2021[:now] - 2.months)

        RefreshReportingViews.refresh_v2

        with_reporting_time_zone do
          expect(described_class.where(htn_treatment_outcome_in_last_2_months: "uncontrolled", month_date: june_2021[:now]).pluck(:patient_id))
            .to include(patient_uncontrolled.id)
          expect(described_class.where(htn_treatment_outcome_in_last_2_months: %w[uncontrolled controlled], month_date: june_2021[:now]).pluck(:patient_id))
            .not_to include(patient_bp_over_2_months.id)
        end
      end
    end

    describe "htn_treatment_outcome_in_quarter is set to" do
      it "missed_visit if the patient hasn't visited in the quarter" do
        this_quarter = june_2021[:now]
        one_quarter_ago = june_2021[:now] - 3.months

        patient_1 = create(:patient, recorded_at: june_2021[:long_ago])
        create(:encounter, patient: patient_1, encountered_on: this_quarter)
        patient_2 = create(:patient, recorded_at: june_2021[:long_ago])
        create(:encounter, patient: patient_2, encountered_on: one_quarter_ago)
        patient_3 = create(:patient, recorded_at: june_2021[:long_ago])
        RefreshReportingViews.refresh_v2

        with_reporting_time_zone do
          expect(described_class.where(htn_treatment_outcome_in_quarter: "missed_visit", month_date: this_quarter).pluck(:patient_id))
            .to include(patient_2.id, patient_3.id)
          expect(described_class.where(htn_treatment_outcome_in_quarter: "missed_visit", month_date: this_quarter).pluck(:patient_id))
            .not_to include(patient_1.id)
        end
      end

      it "visited_no_bp if the patient visited, but didn't get a BP taken in this quarter" do
        patient_bp_in_last_quarter = create(:patient, recorded_at: june_2021[:long_ago])
        create(:prescription_drug,
          device_created_at: june_2021[:now] - 1.month,
          facility: patient_bp_in_last_quarter.registration_facility,
          patient: patient_bp_in_last_quarter,
          user: patient_bp_in_last_quarter.registration_user)
        create(:blood_pressure, patient: patient_bp_in_last_quarter, recorded_at: june_2021[:now] - 3.months)

        patient_bp_in_this_quarter = create(:patient, recorded_at: june_2021[:long_ago])
        create(:prescription_drug,
          device_created_at: june_2021[:now] - 1.month,
          facility: patient_bp_in_this_quarter.registration_facility,
          patient: patient_bp_in_this_quarter,
          user: patient_bp_in_this_quarter.registration_user)
        create(:blood_pressure, patient: patient_bp_in_this_quarter, recorded_at: june_2021[:now])

        patient_with_no_bp = create(:patient, recorded_at: june_2021[:long_ago])
        create(:prescription_drug,
          device_created_at: june_2021[:now] - 1.month,
          facility: patient_with_no_bp.registration_facility,
          patient: patient_with_no_bp,
          user: patient_with_no_bp.registration_user)
        RefreshReportingViews.refresh_v2

        with_reporting_time_zone do
          expect(described_class.where(htn_treatment_outcome_in_quarter: "visited_no_bp", month_date: june_2021[:now]).pluck(:patient_id))
            .to include(patient_bp_in_last_quarter.id, patient_with_no_bp.id)
          expect(described_class.where(htn_treatment_outcome_in_quarter: "visited_no_bp", month_date: june_2021[:now]).pluck(:patient_id))
            .not_to include(patient_bp_in_this_quarter.id)
        end
      end

      it "controlled if there is a BP measured in this quarter that is under control" do
        patient_controlled = create(:patient, recorded_at: june_2021[:long_ago])
        create(:bp_with_encounter, :under_control, patient: patient_controlled, recorded_at: june_2021[:now])

        patient_bp_in_last_quarter = create(:patient, recorded_at: june_2021[:long_ago])
        create(:bp_with_encounter, patient: patient_bp_in_last_quarter, recorded_at: june_2021[:now] - 3.months)

        RefreshReportingViews.refresh_v2

        with_reporting_time_zone do
          expect(described_class.where(htn_treatment_outcome_in_quarter: "controlled", month_date: june_2021[:now]).pluck(:patient_id))
            .to include(patient_controlled.id)
          expect(described_class.where(htn_treatment_outcome_in_quarter: %w[uncontrolled controlled], month_date: june_2021[:now]).pluck(:patient_id))
            .not_to include(patient_bp_in_last_quarter.id)
        end
      end

      it "uncontrolled if there is a BP measured in this quarter that is not under control" do
        patient_uncontrolled = create(:patient, recorded_at: june_2021[:long_ago])
        create(:bp_with_encounter, :hypertensive, patient: patient_uncontrolled, recorded_at: june_2021[:now])

        patient_bp_in_last_quarter = create(:patient, recorded_at: june_2021[:long_ago])
        create(:bp_with_encounter, patient: patient_bp_in_last_quarter, recorded_at: june_2021[:now] - 3.months)

        RefreshReportingViews.refresh_v2

        with_reporting_time_zone do
          expect(described_class.where(htn_treatment_outcome_in_quarter: "uncontrolled", month_date: june_2021[:now]).pluck(:patient_id))
            .to include(patient_uncontrolled.id)
          expect(described_class.where(htn_treatment_outcome_in_quarter: %w[uncontrolled controlled], month_date: june_2021[:now]).pluck(:patient_id))
            .not_to include(patient_bp_in_last_quarter.id)
        end
      end
    end

    describe "months_since_registration" do
      it "computes it correctly" do
        patient_1 = create(:patient, recorded_at: june_2021[:under_12_months_ago])
        patient_2 = create(:patient, recorded_at: june_2021[:over_12_months_ago])
        patient_3 = create(:patient, recorded_at: june_2021[:now])
        patient_4 = create(:patient, recorded_at: june_2021[:over_3_months_ago])

        RefreshReportingViews.refresh_v2
        with_reporting_time_zone do
          expect(described_class.find_by(patient_id: patient_1.id, month_string: june_2021[:month_string]).months_since_registration).to eq 11
          expect(described_class.find_by(patient_id: patient_2.id, month_string: june_2021[:month_string]).months_since_registration).to eq 12
          expect(described_class.find_by(patient_id: patient_3.id, month_string: june_2021[:month_string]).months_since_registration).to eq 0
          expect(described_class.find_by(patient_id: patient_4.id, month_string: june_2021[:month_string]).months_since_registration).to eq 3
        end
      end
    end

    describe "quarters_since_registration" do
      it "computes it correctly" do
        patient_1 = create(:patient, recorded_at: june_2021[:now] - 23.months)
        patient_2 = create(:patient, recorded_at: june_2021[:now] - 13.months)
        patient_3 = create(:patient, recorded_at: june_2021[:now] - 4.months)
        patient_4 = create(:patient, recorded_at: june_2021[:now])

        RefreshReportingViews.refresh_v2
        with_reporting_time_zone do
          expect(described_class.find_by(patient_id: patient_1.id, month_string: june_2021[:month_string]).quarters_since_registration).to eq 7
          expect(described_class.find_by(patient_id: patient_2.id, month_string: june_2021[:month_string]).quarters_since_registration).to eq 4
          expect(described_class.find_by(patient_id: patient_3.id, month_string: june_2021[:month_string]).quarters_since_registration).to eq 1
          expect(described_class.find_by(patient_id: patient_4.id, month_string: june_2021[:month_string]).quarters_since_registration).to eq 0
        end
      end
    end

    describe "assigned and registered facility regions" do
      it "computes the assigned facility and parent regions correctly" do
        registration_facility = create(:facility)
        assigned_facility = create(:facility)

        facility_region = assigned_facility.region
        block_region = facility_region.block_region
        district_region = facility_region.district_region
        state_region = facility_region.state_region
        organization_region = facility_region.organization_region

        patient = create(:patient, registration_facility: registration_facility, assigned_facility: assigned_facility)

        RefreshReportingViews.refresh_v2

        with_reporting_time_zone do
          patient_state = described_class.find_by(patient_id: patient.id, month_string: june_2021[:month_string])

          expect(patient_state.assigned_facility_id).to eq(assigned_facility.id)
          expect(patient_state.assigned_facility_region_id).to eq(facility_region.id)
          expect(patient_state.assigned_block_region_id).to eq(block_region.id)
          expect(patient_state.assigned_district_region_id).to eq(district_region.id)
          expect(patient_state.assigned_state_region_id).to eq(state_region.id)
          expect(patient_state.assigned_organization_region_id).to eq(organization_region.id)

          expect(patient_state.assigned_facility_slug).to eq(assigned_facility.slug)
          expect(patient_state.assigned_block_slug).to eq(block_region.slug)
          expect(patient_state.assigned_district_slug).to eq(district_region.slug)
          expect(patient_state.assigned_state_slug).to eq(state_region.slug)
          expect(patient_state.assigned_organization_slug).to eq(organization_region.slug)
        end
      end

      it "computes the registration facility and parent regions correctly" do
        registration_facility = create(:facility)
        assigned_facility = create(:facility)

        facility_region = registration_facility.region
        block_region = facility_region.block_region
        district_region = facility_region.district_region
        state_region = facility_region.state_region
        organization_region = facility_region.organization_region

        patient = create(:patient, registration_facility: registration_facility, assigned_facility: assigned_facility)

        RefreshReportingViews.refresh_v2

        with_reporting_time_zone do
          patient_state = described_class.find_by(patient_id: patient.id, month_string: june_2021[:month_string])

          expect(patient_state.registration_facility_id).to eq(registration_facility.id)
          expect(patient_state.registration_facility_region_id).to eq(facility_region.id)
          expect(patient_state.registration_block_region_id).to eq(block_region.id)
          expect(patient_state.registration_district_region_id).to eq(district_region.id)
          expect(patient_state.registration_state_region_id).to eq(state_region.id)
          expect(patient_state.registration_organization_region_id).to eq(organization_region.id)

          expect(patient_state.registration_facility_slug).to eq(registration_facility.slug)
          expect(patient_state.registration_block_slug).to eq(block_region.slug)
          expect(patient_state.registration_district_slug).to eq(district_region.slug)
          expect(patient_state.registration_state_slug).to eq(state_region.slug)
          expect(patient_state.registration_organization_slug).to eq(organization_region.slug)
        end
      end
    end

    describe "last_bp_state" do
      it "computes last bp state correctly" do
        patient_controlled = create(:patient, recorded_at: june_2021[:long_ago])
        create(:bp_with_encounter, :under_control, patient: patient_controlled, recorded_at: june_2021[:over_3_months_ago])

        patient_uncontrolled = create(:patient, recorded_at: june_2021[:long_ago])
        create(:bp_with_encounter, :hypertensive, patient: patient_uncontrolled, recorded_at: june_2021[:over_3_months_ago])

        patient_no_bp = create(:patient, recorded_at: june_2021[:long_ago])

        RefreshReportingViews.refresh_v2

        with_reporting_time_zone do
          controlled_state = described_class.find_by(patient_id: patient_controlled.id, month_string: june_2021[:month_string])
          uncontrolled_state = described_class.find_by(patient_id: patient_uncontrolled.id, month_string: june_2021[:month_string])
          no_bp_state = described_class.find_by(patient_id: patient_no_bp.id, month_string: june_2021[:month_string])

          expect(controlled_state.last_bp_state).to eq("controlled")
          expect(uncontrolled_state.last_bp_state).to eq("uncontrolled")
          expect(no_bp_state.last_bp_state).to eq("unknown")
        end
      end
    end

    describe "patient timeline" do
      def patient_states(patient, from: nil, to: nil)
        relation = described_class.where(patient_id: patient.id)

        relation = relation.where("month_date >= ? ", from) if from.present?
        relation = relation.where("month_date < ?", to) if to.present?

        relation.order(month_date: :asc)
      end

      it "should have a record for every month between registration and now" do
        with_reporting_time_zone do
          now = june_2021[:now]
          Timecop.freeze(now) do
            two_years_ago = june_2021[:now] - 2.years
            twelve_months_ago = june_2021[:now] - 12.months
            ten_months_ago = june_2021[:now] - 10.months
            seven_months_ago = june_2021[:now] - 7.months
            eight_months_ago = june_2021[:now] - 8.months
            five_months_ago = june_2021[:now] - 5.months
            two_months_ago = june_2021[:now] - 2.months

            # 24 months ago    patient registered
            # 10 months ago    controlled bp taken
            # 8  months ago    visit but no bp (drugs)
            # 5  months ago    uncontrolled bp taken
            patient = create(:patient, recorded_at: two_years_ago)
            create(:bp_with_encounter, :under_control, patient: patient, recorded_at: ten_months_ago)
            create(:prescription_drug, patient: patient, device_created_at: eight_months_ago)
            create(:bp_with_encounter, :hypertensive, patient: patient, recorded_at: five_months_ago)

            RefreshReportingViews.refresh_v2

            # NOTE: we have to run some of these assertions for a range of up until the "current" frozen timestamp, because we build this matview
            # off a join with the reporting_months view, which uses now() and so will always have records up until
            # the actual current time.  Timecop only impacts Ruby, and not the actual system time.
            expect(patient_states(patient, from: two_years_ago, to: now).pluck(:months_since_registration)).to eq((0...24).to_a)
            expect(patient_states(patient, from: two_years_ago, to: now).pluck(:quarters_since_registration))
              .to eq([0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8])

            expect(patient_states(patient, to: ten_months_ago).pluck(:months_since_visit)).to all(be_nil)
            expect(patient_states(patient, from: ten_months_ago, to: eight_months_ago).pluck(:months_since_visit)).to eq((0..1).to_a)
            expect(patient_states(patient, from: eight_months_ago, to: five_months_ago).pluck(:months_since_visit)).to eq((0..2).to_a)
            expect(patient_states(patient, from: five_months_ago, to: now).pluck(:months_since_visit)).to eq((0...5).to_a)

            expect(patient_states(patient, to: ten_months_ago).pluck(:quarters_since_visit)).to all(be_nil)
            expect(patient_states(patient, from: ten_months_ago, to: june_2021[:now] - 3.months).pluck(:quarters_since_visit)).to all eq 0
            expect(patient_states(patient, from: june_2021[:now] - 2.months, to: now).pluck(:quarters_since_visit)).to all eq 1

            expect(patient_states(patient, to: ten_months_ago).pluck(:months_since_bp)).to all(be_nil)
            expect(patient_states(patient, from: ten_months_ago, to: five_months_ago).pluck(:months_since_bp)).to eq((0..4).to_a)
            expect(patient_states(patient, from: five_months_ago, to: now).pluck(:months_since_bp)).to eq((0...5).to_a)

            expect(patient_states(patient, to: ten_months_ago).pluck(:quarters_since_bp)).to all(be_nil)
            expect(patient_states(patient, from: ten_months_ago, to: eight_months_ago).pluck(:quarters_since_bp)).to all eq 0
            expect(patient_states(patient, from: eight_months_ago, to: five_months_ago).pluck(:quarters_since_bp)).to all eq 1
            expect(patient_states(patient, from: five_months_ago, to: two_months_ago).pluck(:quarters_since_bp)).to all eq 0
            expect(patient_states(patient, from: two_months_ago, to: now).pluck(:quarters_since_bp)).to all eq 1

            expect(patient_states(patient, to: ten_months_ago).pluck(:last_bp_state)).to all(eq("unknown"))
            expect(patient_states(patient, from: ten_months_ago, to: five_months_ago).pluck(:last_bp_state)).to all(eq("controlled"))
            expect(patient_states(patient, from: five_months_ago).pluck(:last_bp_state)).to all(eq("uncontrolled"))

            expect(patient_states(patient, to: twelve_months_ago).pluck(:htn_care_state)).to all(eq("under_care"))
            expect(patient_states(patient, from: twelve_months_ago, to: ten_months_ago).pluck(:htn_care_state)).to all(eq("lost_to_follow_up"))
            expect(patient_states(patient, from: ten_months_ago, to: now).pluck(:htn_care_state)).to all(eq("under_care"))

            expect(patient_states(patient, to: ten_months_ago).pluck(:htn_treatment_outcome_in_last_3_months)).to all(eq("missed_visit"))
            expect(patient_states(patient, from: ten_months_ago, to: seven_months_ago).pluck(:htn_treatment_outcome_in_last_3_months)).to all(eq("controlled"))
            expect(patient_states(patient, from: seven_months_ago, to: five_months_ago).pluck(:htn_treatment_outcome_in_last_3_months)).to all(eq("visited_no_bp"))
            expect(patient_states(patient, from: five_months_ago, to: two_months_ago).pluck(:htn_treatment_outcome_in_last_3_months)).to all(eq("uncontrolled"))
            expect(patient_states(patient, from: two_months_ago).pluck(:htn_treatment_outcome_in_last_3_months)).to all(eq("missed_visit"))
          end
        end
      end
    end

    describe "patient diabetes state" do
      around do |example|
        with_reporting_time_zone { example.run }
      end

      it "contains the details of the latest blood sugar measurement for a given month" do
        patient = create(:patient, recorded_at: 3.months.ago)
        blood_sugar_1 = create(:blood_sugar, patient: patient, recorded_at: 1.months.ago)
        blood_sugar_2 = create(:blood_sugar, patient: patient, recorded_at: 2.days.ago)
        blood_sugar_3 = create(:blood_sugar, patient: patient, recorded_at: Time.now)
        blood_sugar_4 = create(:blood_sugar, recorded_at: Time.now)

        refresh_views

        results = Reports::PatientState.all.pluck(:patient_id, :month_date, :blood_sugar_id)

        expect(results).to include(
          [patient.id, june_2021[:one_month_ago].to_date, blood_sugar_1.id],
          [patient.id, june_2021[:now].to_date, blood_sugar_3.id]
        )

        expect(results).not_to include(
          [patient.id, june_2021[:now].to_date, blood_sugar_2.id],
          [patient.id, june_2021[:now].to_date, blood_sugar_4.id]
        )
      end

      it "contains the details of the latest blood sugar measurement from previous months if there is none in the given month" do
        patient = create(:patient, recorded_at: 6.months.ago)
        blood_sugar_1 = create(:blood_sugar, patient: patient, recorded_at: 4.months.ago)
        blood_sugar_2 = create(:blood_sugar, patient: patient, recorded_at: 2.months.ago)
        blood_sugar_3 = create(:blood_sugar, patient: patient, recorded_at: Time.now)

        refresh_views

        results = Reports::PatientState.all.pluck(:patient_id, :month_date, :blood_sugar_id)

        expect(results).to include(
          [patient.id, june_2021[:four_months_ago].to_date, blood_sugar_1.id],
          [patient.id, june_2021[:three_months_ago].to_date, blood_sugar_1.id],
          [patient.id, june_2021[:two_months_ago].to_date, blood_sugar_2.id],
          [patient.id, june_2021[:one_month_ago].to_date, blood_sugar_2.id],
          [patient.id, june_2021[:now].to_date, blood_sugar_3.id]
        )
      end

      it "contains the blood sugar risk state based on the latest blood sugar measurement" do
        patients = create_list(:patient, 4, recorded_at: 6.months.ago)
        [[patients.first, :random],
          [patients.second, :post_prandial],
          [patients.third, :fasting],
          [patients.fourth, :hba1c]].each do |(patient, blood_sugar_type)|
          create(:blood_sugar, blood_sugar_type, :bs_below_200, patient: patient, recorded_at: Time.now)
          create(:blood_sugar, blood_sugar_type, :bs_200_to_300, patient: patient, recorded_at: 1.month.ago)
          create(:blood_sugar, blood_sugar_type, :bs_over_300, patient: patient, recorded_at: 2.months.ago)
        end

        refresh_views

        results = Reports::PatientState.all.pluck(:patient_id, :month_date, :blood_sugar_type, :blood_sugar_value, :blood_sugar_risk_state)

        # Random blood sugar
        expect(results).to include(
          [patients.first.id, june_2021[:now].to_date, "random", 150, "bs_below_200"],
          [patients.first.id, june_2021[:one_month_ago].to_date, "random", 250, "bs_200_to_300"],
          [patients.first.id, june_2021[:two_months_ago].to_date, "random", 350, "bs_over_300"]
        )

        # Post prandial blood sugar
        expect(results).to include(
          [patients.second.id, june_2021[:now].to_date, "post_prandial", 150, "bs_below_200"],
          [patients.second.id, june_2021[:one_month_ago].to_date, "post_prandial", 250, "bs_200_to_300"],
          [patients.second.id, june_2021[:two_months_ago].to_date, "post_prandial", 350, "bs_over_300"]
        )

        # Fasting blood sugar
        expect(results).to include(
          [patients.third.id, june_2021[:now].to_date, "fasting", 100, "bs_below_200"],
          [patients.third.id, june_2021[:one_month_ago].to_date, "fasting", 165, "bs_200_to_300"],
          [patients.third.id, june_2021[:two_months_ago].to_date, "fasting", 225, "bs_over_300"]
        )

        # Hba1c blood sugar
        expect(results).to include(
          [patients.fourth.id, june_2021[:now].to_date, "hba1c", 6.5, "bs_below_200"],
          [patients.fourth.id, june_2021[:one_month_ago].to_date, "hba1c", 8.5, "bs_200_to_300"],
          [patients.fourth.id, june_2021[:two_months_ago].to_date, "hba1c", 9.5, "bs_over_300"]
        )
      end

      it "contains a count of months and quarters since the latest blood sugar measurement" do
        patient = create(:patient, recorded_at: 6.months.ago)
        blood_sugar_1 = create(:blood_sugar, patient: patient, recorded_at: 4.months.ago)
        blood_sugar_2 = create(:blood_sugar, patient: patient, recorded_at: 1.months.ago)
        blood_sugar_3 = create(:blood_sugar, patient: patient, recorded_at: Time.now)

        refresh_views

        results = Reports::PatientState.all.pluck(:patient_id, :month_date, :blood_sugar_id, :months_since_bs, :quarters_since_bs)

        expect(results).to include(
          [patient.id, june_2021[:six_months_ago].to_date, nil, nil, nil],
          [patient.id, june_2021[:five_months_ago].to_date, nil, nil, nil],
          [patient.id, june_2021[:four_months_ago].to_date, blood_sugar_1.id, 0, 0],
          [patient.id, june_2021[:three_months_ago].to_date, blood_sugar_1.id, 1, 0],
          [patient.id, june_2021[:two_months_ago].to_date, blood_sugar_1.id, 2, 1],
          [patient.id, june_2021[:one_month_ago].to_date, blood_sugar_2.id, 0, 0],
          [patient.id, june_2021[:now].to_date, blood_sugar_3.id, 0, 0]
        )
      end

      it "contains the diabetes treatment outcome for a patient over the last 3 months" do
        # Has no visit in the last 3 months
        missed_visit_patient = create(:patient, recorded_at: 6.months.ago)
        create(:blood_sugar, :with_encounter, patient: missed_visit_patient, recorded_at: 6.months.ago)

        # Has visited in the last 3 months but has no BS measurement
        visited_no_bs_patient = create(:patient, recorded_at: 6.months.ago)
        # This BS measurement is not considered since it's older than 3 months
        create(:blood_sugar, :with_encounter, patient: visited_no_bs_patient, recorded_at: 3.months.ago)
        create(:blood_pressure, :with_encounter, patient: visited_no_bs_patient, recorded_at: 2.months.ago)

        # Have BS measurement at different risk states in last 3 months
        bs_below_200_patient = create(:patient, recorded_at: 6.months.ago)
        create(:blood_sugar, :with_encounter, :bs_below_200, patient: bs_below_200_patient, recorded_at: 2.months.ago)

        bs_200_to_300_patient = create(:patient, recorded_at: 6.months.ago)
        create(:blood_sugar, :with_encounter, :bs_below_200, patient: bs_200_to_300_patient, recorded_at: 2.months.ago)
        create(:blood_sugar, :with_encounter, :bs_200_to_300, patient: bs_200_to_300_patient, recorded_at: 1.months.ago)

        bs_over_300_patient = create(:patient, recorded_at: 6.months.ago)
        create(:blood_sugar, :with_encounter, :bs_over_300, patient: bs_over_300_patient, recorded_at: 2.months.ago)

        refresh_views

        results = Reports::PatientState.where(month_date: june_2021[:now]).pluck(:patient_id, :diabetes_treatment_outcome_in_last_3_months)
        expect(results).to include(
          [missed_visit_patient.id, "missed_visit"],
          [visited_no_bs_patient.id, "visited_no_bs"],
          [bs_below_200_patient.id, "bs_below_200"],
          [bs_200_to_300_patient.id, "bs_200_to_300"],
          [bs_over_300_patient.id, "bs_over_300"]
        )
      end

      it "contains a patients diabetes treatment outcome over the last 2 months" do
        # Has no visit in the last 2 months
        missed_visit_patient = create(:patient, recorded_at: 6.months.ago)
        create(:blood_sugar, :with_encounter, patient: missed_visit_patient, recorded_at: 6.months.ago)

        # Has visited in the last 2 months but has no BS measurement
        visited_no_bs_patient = create(:patient, recorded_at: 6.months.ago)
        # This BS measurement is not considered since it's older than 2 months
        create(:blood_sugar, :with_encounter, patient: visited_no_bs_patient, recorded_at: 2.months.ago)
        create(:blood_pressure, :with_encounter, patient: visited_no_bs_patient, recorded_at: 40.days.ago)

        # Have BS measurement at different risk states in last 2 months
        bs_below_200_patient = create(:patient, recorded_at: 6.months.ago)
        create(:blood_sugar, :with_encounter, :bs_below_200, patient: bs_below_200_patient, recorded_at: 1.month.ago)

        bs_200_to_300_patient = create(:patient, recorded_at: 6.months.ago)
        create(:blood_sugar, :with_encounter, :bs_below_200, patient: bs_200_to_300_patient, recorded_at: 1.month.ago)
        create(:blood_sugar, :with_encounter, :bs_200_to_300, patient: bs_200_to_300_patient, recorded_at: 10.days.ago)

        bs_over_300_patient = create(:patient, recorded_at: 6.months.ago)
        create(:blood_sugar, :with_encounter, :bs_over_300, patient: bs_over_300_patient, recorded_at: 40.days.ago)

        refresh_views

        results = Reports::PatientState.where(month_date: june_2021[:now]).pluck(:patient_id, :diabetes_treatment_outcome_in_last_2_months)
        expect(results).to include(
          [missed_visit_patient.id, "missed_visit"],
          [visited_no_bs_patient.id, "visited_no_bs"],
          [bs_below_200_patient.id, "bs_below_200"],
          [bs_200_to_300_patient.id, "bs_200_to_300"],
          [bs_over_300_patient.id, "bs_over_300"]
        )
      end

      it "contains a patients diabetes treatment outcome over the quarter" do
        # Has no visit in the last quarter
        missed_visit_patient = create(:patient, recorded_at: 6.months.ago)
        create(:blood_sugar, :with_encounter, patient: missed_visit_patient, recorded_at: june_2021[:three_months_ago])

        # Has visited in the last quarter but has no BS measurement
        visited_no_bs_patient = create(:patient, recorded_at: 6.months.ago)
        # This BS measurement is not considered since it's in the previous quarter
        create(:blood_sugar, :with_encounter, patient: visited_no_bs_patient, recorded_at: june_2021[:three_months_ago])
        create(:blood_pressure, :with_encounter, patient: visited_no_bs_patient, recorded_at: 2.months.ago)

        # Have BS measurement at different risk states in last quarter
        bs_below_200_patient = create(:patient, recorded_at: 6.months.ago)
        create(:blood_sugar, :with_encounter, :bs_below_200, patient: bs_below_200_patient, recorded_at: 1.month.ago)

        bs_200_to_300_patient = create(:patient, recorded_at: 6.months.ago)
        create(:blood_sugar, :with_encounter, :bs_below_200, patient: bs_200_to_300_patient, recorded_at: 1.month.ago)
        create(:blood_sugar, :with_encounter, :bs_200_to_300, patient: bs_200_to_300_patient, recorded_at: 10.days.ago)

        bs_over_300_patient = create(:patient, recorded_at: 6.months.ago)
        create(:blood_sugar, :with_encounter, :bs_over_300, patient: bs_over_300_patient, recorded_at: 40.days.ago)

        refresh_views

        results = Reports::PatientState.where(month_date: june_2021[:now]).pluck(:patient_id, :diabetes_treatment_outcome_in_quarter)
        expect(results).to include(
          [missed_visit_patient.id, "missed_visit"],
          [visited_no_bs_patient.id, "visited_no_bs"],
          [bs_below_200_patient.id, "bs_below_200"],
          [bs_200_to_300_patient.id, "bs_200_to_300"],
          [bs_over_300_patient.id, "bs_over_300"]
        )
      end
    end
  end
end
