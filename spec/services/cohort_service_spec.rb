require "rails_helper"

RSpec.describe CohortService, type: :model do
  let(:jan_5) { Time.parse("Jan 5th, 2020 00:00:00+00:00") }
  let(:apr_5) { Time.parse("Apr 5th, 2020 00:00:00+00:00") }
  let(:jul_5) { Time.parse("Jul 5th, 2020 00:00:00+00:00") }
  let(:user) { create(:user) }
  let(:organization) { common_org }
  let(:user) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
  let(:facility_group) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }

  [true, false].each do |v2_flag|
    context "with reporting_schema_v2=>#{v2_flag}" do
      before do
        RequestStore.store[:reporting_schema_v2] = v2_flag
      end

      if v2_flag
        def refresh_views
          RefreshReportingViews.new.refresh_v2
        end
      else
        def refresh_views
          ActiveRecord::Base.transaction do
            LatestBloodPressuresPerPatientPerMonth.refresh
            LatestBloodPressuresPerPatientPerQuarter.refresh
            PatientRegistrationsPerDayPerFacility.refresh
          end
        end
      end

      it "returns cohort numbers for the selected quarters" do
        facility = create(:facility)

        # Q1 patients
        # - 6 registered in Q1
        # - 3 controlled in Q2
        # - 1 uncontrolled in Q2
        # - 2 no BP in Q2

        q1_patients = [
          create(:patient, registration_facility: facility, registration_user: user, recorded_at: jan_5),
          create(:patient, registration_facility: facility, registration_user: user, recorded_at: jan_5 + 10.days),
          create(:patient, registration_facility: facility, registration_user: user, recorded_at: jan_5 + 20.days),
          create(:patient, registration_facility: facility, registration_user: user, recorded_at: jan_5 + 30.days),
          create(:patient, registration_facility: facility, registration_user: user, recorded_at: jan_5 + 45.days),
          create(:patient, registration_facility: facility, registration_user: user, recorded_at: jan_5 + 60.days)
        ]

        _q1_bps = [
          create(:bp_with_encounter, :under_control, recorded_at: apr_5, facility: facility, patient: q1_patients[0]),
          create(:bp_with_encounter, :under_control, recorded_at: apr_5 + 10.days, facility: facility, patient: q1_patients[1]),
          create(:bp_with_encounter, :under_control, recorded_at: apr_5 + 30.days, facility: facility, patient: q1_patients[2]),
          create(:bp_with_encounter, :hypertensive, recorded_at: apr_5 + 60.days, facility: facility, patient: q1_patients[3])
        ]

        # Q2 patients
        # - 8 registered in Q2
        # - 4 controlled in Q3
        # - 3 uncontrolled in Q3
        # - 1 no BP in Q3

        q2_patients = [
          create(:patient, registration_facility: facility, registration_user: user, recorded_at: apr_5),
          create(:patient, registration_facility: facility, registration_user: user, recorded_at: apr_5 + 10.days),
          create(:patient, registration_facility: facility, registration_user: user, recorded_at: apr_5 + 20.days),
          create(:patient, registration_facility: facility, registration_user: user, recorded_at: apr_5 + 30.days),
          create(:patient, registration_facility: facility, registration_user: user, recorded_at: apr_5 + 40.days),
          create(:patient, registration_facility: facility, registration_user: user, recorded_at: apr_5 + 50.days),
          create(:patient, registration_facility: facility, registration_user: user, recorded_at: apr_5 + 60.days),
          create(:patient, registration_facility: facility, registration_user: user, recorded_at: apr_5 + 70.days)
        ]

        _q2_bps = [
          create(:bp_with_encounter, :under_control, recorded_at: jul_5, facility: facility, patient: q2_patients[0]),
          create(:bp_with_encounter, :under_control, recorded_at: jul_5 + 10.days, facility: facility, patient: q2_patients[1]),
          create(:bp_with_encounter, :under_control, recorded_at: jul_5 + 20.days, facility: facility, patient: q2_patients[2]),
          create(:bp_with_encounter, :under_control, recorded_at: jul_5 + 30.days, facility: facility, patient: q2_patients[3]),
          create(:bp_with_encounter, :hypertensive, recorded_at: jul_5 + 40.days, facility: facility, patient: q2_patients[4]),
          create(:bp_with_encounter, :hypertensive, recorded_at: jul_5 + 50.days, facility: facility, patient: q2_patients[5]),
          create(:bp_with_encounter, :hypertensive, recorded_at: jul_5 + 60.days, facility: facility, patient: q2_patients[6])
        ]

        # Other facility data that shouldn't interfere

        other_patients = [
          create(:patient, recorded_at: jan_5, registration_user: user),
          create(:patient, recorded_at: apr_5, registration_user: user),
          create(:patient, recorded_at: jul_5, registration_user: user)
        ]

        _other_bps = [
          create(:blood_pressure, :under_control, recorded_at: jul_5, facility: facility, patient: other_patients[0]),
          create(:blood_pressure, :hypertensive, recorded_at: jul_5 + 10.days, facility: facility, patient: other_patients[1])
        ]

        refresh_views

        quarters = [
          Period.quarter(apr_5),
          Period.quarter(jul_5)
        ]
        cohort_service = CohortService.new(region: facility, periods: quarters)

        expect(cohort_service.call).to eq(
          [
            {
              "controlled" => 3,
              "no_bp" => 2,
              "patients_registered" => "Q1-2020",
              "registered" => 6,
              "results_in" => "Q2-2020",
              "uncontrolled" => 1
            },
            {
              "controlled" => 4,
              "no_bp" => 1,
              "patients_registered" => "Q2-2020",
              "registered" => 8,
              "results_in" => "Q3-2020",
              "uncontrolled" => 3
            }
          ]
        )
      end

      fit "returns cohort numbers for districts" do
        facility_1 = create(:facility, facility_group: facility_group)
        facility_2 = create(:facility, facility_group: facility_group)
        q1_patients = [
          create(:patient, registration_facility: facility_1, registration_user: user, recorded_at: jan_5),
          create(:patient, registration_facility: facility_1, registration_user: user, recorded_at: jan_5),
          create(:patient, registration_facility: facility_2, registration_user: user, recorded_at: jan_5 + 10.days),
        ]
        _q1_bps = [
          create(:bp_with_encounter, :hypertensive, recorded_at: apr_5, facility: facility_1, patient: q1_patients[0]),
          create(:bp_with_encounter, :under_control, recorded_at: apr_5 + 10.days, facility: facility_1, patient: q1_patients[0]),
          create(:bp_with_encounter, :under_control, recorded_at: apr_5 + 10.days, facility: facility_1, patient: q1_patients[1]),
          create(:bp_with_encounter, :hypertensive, recorded_at: apr_5 + 10.days, facility: facility_2, patient: q1_patients[2])
        ]
        _q2_patients = [
          create(:patient, registration_facility: facility_1, registration_user: user, recorded_at: apr_5),
          # create(:patient, registration_facility: facility_2, registration_user: user, recorded_at: jan_5 + 10.days),
        ]
        refresh_views

        quarters = [
          Period.quarter(apr_5),
          Period.quarter(jul_5)
        ]
        result = CohortService.new(region: facility_group, periods: quarters).call
        q1 = result[0]
        q2 = result[1]
        expect(q1).to eq({
          "controlled" => 2,
          "no_bp" => 0,
          "patients_registered" => "Q1-2020",
          "registered" => 3,
          "results_in" => "Q2-2020",
          "uncontrolled" => 1
        })
        expect(q2).to eq({
          "controlled" => 0,
          "no_bp" => 1,
          "patients_registered" => "Q2-2020",
          "registered" => 1,
          "results_in" => "Q3-2020",
          "uncontrolled" => 0
        })
      end

    end
  end
end
