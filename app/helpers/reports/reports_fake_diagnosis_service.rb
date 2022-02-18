module Reports
  class ReportsFakeDiagnosisService
    def initialize(facility_name)
      @hypertension_assigned_patients = {
        "name" => "Assigned patients",
        "total" => 793,
        "subtitle" => "Patients expected to follow-up at #{facility_name} to receive hypertension treatment.",
        "breakdown" => [
          {"title" => "Registered patients", "value" => 877},
          {"title" => "Transferred-in", "value" => 3},
          {"title" => "Transferred-out", "value" => -87}
        ]
      }
      @hypertension_registered_patients = {
        "name" => "Total registered patients",
        "data_type" => "number",
        "subtitle" => "All hypertensive patients registered in #{facility_name}",
        "breakdown" => [
          {"month" => "Aug-2021", "value" => 187},
          {"month" => "Sep-2021", "value" => 320},
          {"month" => "Oct-2021", "value" => 498},
          {"month" => "Nov-2021", "value" => 570},
          {"month" => "Dec-2021", "value" => 634},
          {"month" => "Jan-2022", "value" => 877}
        ]
      }
      @hypertension_monthly_follow_up_patients = {
        "name" => "Monthly follow-up patients",
        "data_type" => "number",
        "subtitle" => "Hypertension patients with a BP taken, a blood sugar taken, an appointment scheduled, or a medication updated at #{facility_name} during a month.",
        "breakdown" => [
          {"month" => "Aug-2021", "value" => 182},
          {"month" => "Sep-2021", "value" => 175},
          {"month" => "Oct-2021", "value" => 148},
          {"month" => "Nov-2021", "value" => 254},
          {"month" => "Dec-2021", "value" => 358},
          {"month" => "Jan-2022", "value" => 158}
        ]
      }
      @hypertension_bp_controlled = {
        "name" => "BP controlled",
        "data_type" => "percentage",
        "subtitle" => "Hypertension patients in #{facility_name} registered >3 months ago with BP <140/90 at their last visit in the last 3 months.",
        "breakdown" => [
          {
            "month" => "Aug-2021",
            "value" => 32,
            "period_start" => "Jun-2021",
            "period_end" => "Aug-2021",
            "registration_period" => "May-2021",
            "total_patients" => 116,
            "registered_patients" => 363
          },
          {
            "month" => "Sep-2021",
            "value" => 44,
            "period_start" => "Jul-2021",
            "period_end" => "Sep-2021",
            "registration_period" => "Jun-2021",
            "total_patients" => 154,
            "registered_patients" => 350
          },
          {
            "month" => "Oct-2021",
            "value" => 37,
            "period_start" => "Aug-2021",
            "period_end" => "Oct-2021",
            "registration_period" => "Jul-2021",
            "total_patients" => 177,
            "registered_patients" => 478
          },
          {
            "month" => "Nov-2021",
            "value" => 34,
            "period_start" => "Sep-2021",
            "period_end" => "Nov-2021",
            "registration_period" => "Aug-2021",
            "total_patients" => 165,
            "registered_patients" => 485
          },
          {
            "month" => "Dec-2021",
            "value" => 32,
            "period_start" => "Oct-2021",
            "period_end" => "Dec-2021",
            "registration_period" => "Sep-2021",
            "total_patients" => 176,
            "registered_patients" => 550
          },
          {
            "month" => "Jan-2022",
            "value" => 31,
            "period_start" => "Nov-2021",
            "period_end" => "Jan-2022",
            "registration_period" => "Oct-2021",
            "total_patients" => 165,
            "registered_patients" => 532 
          }
        ]
      }
      @hypertension_bp_not_controlled = {
        "name" => "BP not controlled",
        "data_type" => "percentage",
        "subtitle" => "Hypertension patients in #{facility_name} registered >3 months ago with BP ≥140/90 at their last visit in the last 3 months.",
        "breakdown" => [
          {
            "month" => "Aug-2021",
            "value" => 13,
            "period_start" => "Jun-2021",
            "period_end" => "Aug-2021",
            "registration_period" => "May-2021",
            "total_patients" => 47,
            "registered_patients" => 363
          },
          {
            "month" => "Sep-2021",
            "value" => 14,
            "period_start" => "Jul-2021",
            "period_end" => "Sep-2021",
            "registration_period" => "Jun-2021",
            "total_patients" => 49,
            "registered_patients" => 350
          },
          {
            "month" => "Oct-2021",
            "value" => 12,
            "period_start" => "Aug-2021",
            "period_end" => "Oct-2021",
            "registration_period" => "Jul-2021",
            "total_patients" => 57,
            "registered_patients" => 478
          },
          {
            "month" => "Nov-2021",
            "value" => 18,
            "period_start" => "Sep-2021",
            "period_end" => "Nov-2021",
            "registration_period" => "Aug-2021",
            "total_patients" => 87,
            "registered_patients" => 485
          },
          {
            "month" => "Dec-2021",
            "value" => 23,
            "period_start" => "Oct-2021",
            "period_end" => "Dec-2021",
            "registration_period" => "Sep-2021",
            "total_patients" => 127,
            "registered_patients" => 550
          },
          {
            "month" => "Jan-2022",
            "value" => 15,
            "period_start" => "Nov-2021",
            "period_end" => "Jan-2022",
            "registration_period" => "Oct-2021",
            "total_patients" => 80,
            "registered_patients" => 532 
          }
        ]
      }
      @hypertension_missed_visits = {
        "name" => "Missed visits",
        "data_type" => "percentage",
        "subtitle" => "Hypertension patients in #{facility_name} registered >3 months ago with no visit in the last 3 months.",
        "breakdown" => [
          {
            "month" => "Aug-2021",
            "value" => 17,
            "period_start" => "Jun-2021",
            "period_end" => "Aug-2021",
            "registration_period" => "May-2021",
            "total_patients" => 62,
            "registered_patients" => 363
          },
          {
            "month" => "Sep-2021",
            "value" => 18,
            "period_start" => "Jul-2021",
            "period_end" => "Sep-2021",
            "registration_period" => "Jun-2021",
            "total_patients" => 63,
            "registered_patients" => 350
          },
          {
            "month" => "Oct-2021",
            "value" => 18,
            "period_start" => "Aug-2021",
            "period_end" => "Oct-2021",
            "registration_period" => "Jul-2021",
            "total_patients" => 86,
            "registered_patients" => 478
          },
          {
            "month" => "Nov-2021",
            "value" => 19,
            "period_start" => "Sep-2021",
            "period_end" => "Nov-2021",
            "registration_period" => "Aug-2021",
            "total_patients" => 92,
            "registered_patients" => 485
          },
          {
            "month" => "Dec-2021",
            "value" => 27,
            "period_start" => "Oct-2021",
            "period_end" => "Dec-2021",
            "registration_period" => "Sep-2021",
            "total_patients" => 149,
            "registered_patients" => 550
          },
          {
            "month" => "Jan-2022",
            "value" => 16,
            "period_start" => "Nov-2021",
            "period_end" => "Jan-2022",
            "registration_period" => "Oct-2021",
            "total_patients" => 85,
            "registered_patients" => 532 
          }
        ]
      }
      @hypertension_quarterly_cohort_reports = {
        "name" => "Quarterly cohort reports",
        "data_type" => "percentage",
        "subtitle" => "The result for all assigned hypertensive patients registered in a quarter at their follow-up visit in the following two quarters.",
        "breakdown" => [
          {
            "result_period" => "Q4-2021/Q1-2022",
            "registration_period" => "Q3-2021",
            "total_patients" => 227,
            "bp_controlled" => 42,
            "bp_not_controlled" => 28,
            "missed_visits" => 29
          },
          {
            "result_period" => "Q3-2021/Q4-2021",
            "registration_period" => "Q2-2021",
            "total_patients" => 207,
            "bp_controlled" => 50,
            "bp_not_controlled" => 48,
            "missed_visits" => 2 
          },
          {
            "result_period" => "Q2-2021/Q3-2021",
            "registration_period" => "Q1-2021",
            "total_patients" => 247,
            "bp_controlled" => 42,
            "bp_not_controlled" => 26,
            "missed_visits" => 31 
          }
        ]
      }
    end

    def call
      {
        "hypertension_assigned_patients" => @hypertension_assigned_patients,
        "hypertension_registered_patients" => @hypertension_registered_patients,
        "hypertension_monthly_follow_up_patients" => @hypertension_monthly_follow_up_patients,
        "hypertension_bp_controlled" => @hypertension_bp_controlled,
        "hypertension_bp_not_controlled" => @hypertension_bp_not_controlled,
        "hypertension_missed_visits" => @hypertension_missed_visits,
        "hypertension_quarterly_cohort_reports" => @hypertension_quarterly_cohort_reports
      }
    end
  end
end