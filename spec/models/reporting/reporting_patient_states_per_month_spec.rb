require "rails_helper"

RSpec.describe Reporting::ReportingPatientStatesPerMonth, type: :model do
  describe "Associations" do
    it { should belong_to(:patient) }
  end

  # TODO: extract this to a rspec helper
  def with_reporting_time_zones(&blk)
    Time.use_zone(Period::REPORTING_TIME_ZONE) do
      Groupdate.time_zone = Period::REPORTING_TIME_ZONE
      blk.call
      Groupdate.time_zone = nil
    end
  end

  def ltfu_patient_ids(month_date: Date.current.beginning_of_month)
    described_class
      .where(htn_care_state: "lost_to_follow_up", month_date: month_date)
      .pluck(:id)
  end

  def under_care_patient_ids(month_date: Date.current.beginning_of_month)
    described_class
      .where(htn_care_state: "under_care", month_date: month_date)
      .pluck(:id)
  end

  def test_times
    # We explicitly set the times in the reporting TZ here, but don't use the block helper because its a hassle w/
    # all the local vars we need
    timezone = Time.find_zone(Period::REPORTING_TIME_ZONE)
    now = timezone.local(2021, 6, 1, 0, 0, 0)
    {
      now: now,
      long_ago: now - 5.years,
      under_a_year_ago: timezone.local(2020, 7, 1, 0, 0, 1), # Beginning of July 1 2020
      over_a_year_ago: timezone.local(2020, 6, 30, 23, 59, 59), # End of June 30 2020
      beginning_of_month: now, # Beginning of June 1 2021
      three_months_ago: timezone.local(2021, 3, 31, 0, 0, 0), # End of March 2021
      end_of_month: timezone.local(2021, 6, 30, 23, 59, 59) # End of June 30 2021
    }
  end

  context "indicators" do
    describe "htn_care_state" do
      it "marks a dead patient dead" do
        dead_patient = create(:patient, status: Patient.statuses[:dead])
        described_class.refresh
        with_reporting_time_zones do
          expect(described_class.where(htn_care_state: "dead").pluck(:id)).to include(dead_patient.id)
        end
      end

      it "marks a patient registered more than 12 months ago with BP more than 12 months ago as ltfu" do
        patient_registered_13m_ago = Timecop.freeze(13.months.ago) { create(:patient) }
        Timecop.freeze(13.months.ago) { create(:blood_pressure, patient: patient_registered_13m_ago) }

        described_class.refresh
        with_reporting_time_zones do
          expect(ltfu_patient_ids).to include(patient_registered_13m_ago.id)
          expect(under_care_patient_ids).not_to include(patient_registered_13m_ago.id)
        end
      end

      it "marks a patient with no bp as lost to follow up depending on registration date" do
        patient_registered_12m_ago = Timecop.freeze(12.months.ago) { create(:patient) }
        patient_registered_11m_ago = Timecop.freeze(11.months.ago) { create(:patient) }

        described_class.refresh
        with_reporting_time_zones do
          expect(ltfu_patient_ids).to include(patient_registered_12m_ago.id)
          expect(under_care_patient_ids).not_to include(patient_registered_12m_ago.id)

          expect(ltfu_patient_ids).not_to include(patient_registered_11m_ago.id)
          expect(under_care_patient_ids).to include(patient_registered_11m_ago.id)
        end
      end

      it "marks a patient registered long ago, with a recent BP as under care" do
        patient_with_recent_bp = Timecop.freeze(13.months.ago) { create(:patient) }
        Timecop.freeze(11.months.ago) { create(:blood_pressure, patient: patient_with_recent_bp) }

        described_class.refresh
        with_reporting_time_zones do
          expect(ltfu_patient_ids).not_to include(patient_with_recent_bp.id)
          expect(under_care_patient_ids).to include(patient_with_recent_bp.id)
        end
      end

      context "ltfu tests ported from patient_spec.rb" do
        it "bp cutoffs for a year ago" do
          under_care_patient = create(:patient, recorded_at: test_times[:long_ago])
          ltfu_patient = create(:patient, recorded_at: test_times[:long_ago])

          create(:blood_pressure, patient: under_care_patient, recorded_at: test_times[:under_a_year_ago])
          create(:blood_pressure, patient: ltfu_patient, recorded_at: test_times[:over_a_year_ago])

          described_class.refresh

          with_reporting_time_zones do
            expect(ltfu_patient_ids(month_date: test_times[:beginning_of_month])).to include(ltfu_patient.id)
            expect(ltfu_patient_ids(month_date: test_times[:beginning_of_month])).not_to include(under_care_patient.id)
            expect(under_care_patient_ids(month_date: test_times[:beginning_of_month])).to include(under_care_patient.id)
            expect(under_care_patient_ids(month_date: test_times[:beginning_of_month])).not_to include(ltfu_patient.id)
          end
        end

        it "bp cutoffs for now" do
          under_care_patient = create(:patient, recorded_at: test_times[:long_ago])
          ltfu_patient = create(:patient, recorded_at: test_times[:long_ago])

          create(:blood_pressure, patient: under_care_patient, recorded_at: test_times[:end_of_month] - 1.minute)
          create(:blood_pressure, patient: ltfu_patient, recorded_at: test_times[:end_of_month] + 1.minute)

          described_class.refresh
          with_reporting_time_zones do
            expect(ltfu_patient_ids(month_date: test_times[:beginning_of_month])).not_to include(under_care_patient.id)
            expect(ltfu_patient_ids(month_date: test_times[:beginning_of_month])).to include(ltfu_patient.id)
            expect(under_care_patient_ids(month_date: test_times[:beginning_of_month])).not_to include(ltfu_patient.id)
            expect(under_care_patient_ids(month_date: test_times[:beginning_of_month])).to include(under_care_patient.id)
          end
        end

        it "registration cutoffs for a year ago" do
          under_care_patient = create(:patient, recorded_at: test_times[:under_a_year_ago])
          ltfu_patient = create(:patient, recorded_at: test_times[:over_a_year_ago])

          described_class.refresh
          with_reporting_time_zones do
            expect(ltfu_patient_ids(month_date: test_times[:beginning_of_month])).not_to include(under_care_patient.id)
            expect(ltfu_patient_ids(month_date: test_times[:beginning_of_month])).to include(ltfu_patient.id)
            expect(under_care_patient_ids(month_date: test_times[:beginning_of_month])).not_to include(ltfu_patient.id)
            expect(under_care_patient_ids(month_date: test_times[:beginning_of_month])).to include(under_care_patient.id)
          end
        end
      end
    end

    describe "htn_treatment_outcome_in_last_3_months is set to" do
      it "missed_visit if the patient hasn't visited in the last 3 months" do
        patient_1 = create(:patient, recorded_at: test_times[:long_ago])
        create(:encounter, patient: patient_1, encountered_on: test_times[:three_months_ago])
        patient_2 = create(:patient, recorded_at: test_times[:long_ago])
        described_class.refresh

        with_reporting_time_zones do
          expect(described_class.where(htn_treatment_outcome_in_last_3_months: "missed_visit", month_date: test_times[:now]).pluck(:id))
            .to include(patient_1.id, patient_2.id)
        end
      end

      it "visited_no_bp if the patient visited, but didn't get a BP taken in the last 3 months" do
        patient_bp_older_than_3_months = create(:patient, recorded_at: test_times[:long_ago])
        create(:prescription_drug,
          device_created_at: test_times[:now] - 1.month,
          facility: patient_bp_older_than_3_months.registration_facility,
          patient: patient_bp_older_than_3_months,
          user: patient_bp_older_than_3_months.registration_user)
        create(:blood_pressure, patient: patient_bp_older_than_3_months, recorded_at: test_times[:three_months_ago])

        patient_with_no_bp = create(:patient, recorded_at: test_times[:long_ago])
        create(:prescription_drug,
          device_created_at: test_times[:now] - 1.month,
          facility: patient_with_no_bp.registration_facility,
          patient: patient_with_no_bp,
          user: patient_with_no_bp.registration_user)
        described_class.refresh

        with_reporting_time_zones do
          expect(described_class.where(htn_treatment_outcome_in_last_3_months: "visited_no_bp", month_date: test_times[:now]).pluck(:id))
            .to include(patient_bp_older_than_3_months.id, patient_with_no_bp.id)
        end
      end

      it "controlled/uncontrolled if there is a BP measured in the last 3 months that is under/not under control" do
        patient_controlled = create(:patient, recorded_at: test_times[:long_ago])
        create(:blood_pressure, :with_encounter, patient: patient_controlled, recorded_at: test_times[:now] - 1.month, systolic: 139, diastolic: 89)

        patient_uncontrolled = create(:patient, recorded_at: test_times[:long_ago])
        create(:blood_pressure, :with_encounter, patient: patient_uncontrolled, recorded_at: test_times[:now] - 1.months, systolic: 140, diastolic: 90)

        described_class.refresh

        with_reporting_time_zones do
          expect(described_class.where(htn_treatment_outcome_in_last_3_months: "controlled", month_date: test_times[:now]).pluck(:id))
            .to include(patient_controlled.id)
          expect(described_class.where(htn_treatment_outcome_in_last_3_months: "uncontrolled", month_date: test_times[:now]).pluck(:id))
            .to include(patient_uncontrolled.id)
        end
      end
    end
  end
end
