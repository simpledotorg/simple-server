module Reports
  class ReportsFakeFacilityProgressService
    def initialize(facility_name)
      @daily_periods = ["8-Feb-2022", "7-Feb-2022", "6-Feb-2022", "5-Feb-2022", "4-Feb-2022", "3-Feb-2022", "2-Feb-2022"]

      @daily_registered_patients = {
        "total" => 7,
        "breakdown" => [
          {"title" => "Hypertension only", "value" => 2, "row_type" => :header},
          {"title" => "Male", "value" => 1, "row_type" => :secondary},
          {"title" => "Female", "value" => 1, "row_type" => :secondary},
          {"title" => "Transgender", "value" => 0, "row_type" => :secondary},
          {"title" => "Diabetes only", "value" => 1, "row_type" => :header},
          {"title" => "Male", "value" => 0, "row_type" => :secondary},
          {"title" => "Female", "value" => 1, "row_type" => :secondary},
          {"title" => "Transgender", "value" => 0, "row_type" => :secondary},
          {"title" => "Hypertension and diabetes", "value" => 4, "row_type" => :header},
          {"title" => "Male", "value" => 3, "row_type" => :secondary},
          {"title" => "Female", "value" => 0, "row_type" => :secondary},
          {"title" => "Transgender", "value" => 1, "row_type" => :secondary}
        ]
      }

      @daily_follow_up_patients = {
        "total" => 15,
        "breakdown" => [
          {"title" => "Hypertension only", "value" => 3, "row_type" => :header},
          {"title" => "Male", "value" => 1, "row_type" => :secondary},
          {"title" => "Female", "value" => 2, "row_type" => :secondary},
          {"title" => "Transgender", "value" => 0, "row_type" => :secondary},
          {"title" => "Diabetes only", "value" => 2, "row_type" => :header},
          {"title" => "Male", "value" => 1, "row_type" => :secondary},
          {"title" => "Female", "value" => 1, "row_type" => :secondary},
          {"title" => "Transgender", "value" => 0, "row_type" => :secondary},
          {"title" => "Hypertension and diabetes", "value" => 10, "row_type" => :header},
          {"title" => "Male", "value" => 4, "row_type" => :secondary},
          {"title" => "Female", "value" => 4, "row_type" => :secondary},
          {"title" => "Transgender", "value" => 2, "row_type" => :secondary}
        ]
      }

      @monthly_periods = ["Feb-2022", "Jan-2022", "Dec-2021", "Nov-2021", "Oct-2021", "Sep-2021", "Aug-2021"]

      @monthly_registered_patients = {
        "total" => 90,
        "breakdown" => [
          {"title" => "Hypertension only", "value" => 37, "row_type" => :header},
          {"title" => "Male", "value" => 15, "row_type" => :secondary},
          {"title" => "Female", "value" => 15, "row_type" => :secondary},
          {"title" => "Transgender", "value" => 7, "row_type" => :secondary},
          {"title" => "Diabetes only", "value" => 12, "row_type" => :header},
          {"title" => "Male", "value" => 5, "row_type" => :secondary},
          {"title" => "Female", "value" => 6, "row_type" => :secondary},
          {"title" => "Transgender", "value" => 1, "row_type" => :secondary},
          {"title" => "Hypertension and diabetes", "value" => 41, "row_type" => :header},
          {"title" => "Male", "value" => 19, "row_type" => :secondary},
          {"title" => "Female", "value" => 21, "row_type" => :secondary},
          {"title" => "Transgender", "value" => 1, "row_type" => :secondary}
        ]
      }

      @monthly_follow_up_patients = {
        "total" => 158,
        "breakdown" => [
          {"title" => "Hypertension only", "value" => 15, "row_type" => :header},
          {"title" => "Male", "value" => 12, "row_type" => :secondary},
          {"title" => "Female", "value" => 3, "row_type" => :secondary},
          {"title" => "Transgender", "value" => 0, "row_type" => :secondary},
          {"title" => "Diabetes only", "value" => 16, "row_type" => :header},
          {"title" => "Male", "value" => 10, "row_type" => :secondary},
          {"title" => "Female", "value" => 5, "row_type" => :secondary},
          {"title" => "Transgender", "value" => 1, "row_type" => :secondary},
          {"title" => "Hypertension and diabetes", "value" => 127, "row_type" => :header},
          {"title" => "Male", "value" => 77, "row_type" => :secondary},
          {"title" => "Female", "value" => 49, "row_type" => :secondary},
          {"title" => "Transgender", "value" => 1, "row_type" => :secondary}
        ]
      }

      @yearly_periods = ["2022", "2021", "2020", "2019"]

      @yearly_registered_patients = {
        "total" => 810,
        "breakdown" => [
          {"title" => "Hypertension only", "value" => 567, "row_type" => :header},
          {"title" => "Male", "value" => 277, "row_type" => :secondary},
          {"title" => "Female", "value" => 282, "row_type" => :secondary},
          {"title" => "Transgender", "value" => 8, "row_type" => :secondary},
          {"title" => "Diabetes only", "value" => 201, "row_type" => :header},
          {"title" => "Male", "value" => 115, "row_type" => :secondary},
          {"title" => "Female", "value" => 83, "row_type" => :secondary},
          {"title" => "Transgender", "value" => 3, "row_type" => :secondary},
          {"title" => "Hypertension and diabetes", "value" => 42, "row_type" => :header},
          {"title" => "Male", "value" => 27, "row_type" => :secondary},
          {"title" => "Female", "value" => 15, "row_type" => :secondary},
          {"title" => "Transgender", "value" => 0, "row_type" => :secondary}
        ]
      }

      @yearly_follow_up_patients = {
        "total" => 1422,
        "breakdown" => [
          {"title" => "Hypertension only", "value" => 456, "row_type" => :header},
          {"title" => "Male", "value" => 220, "row_type" => :secondary},
          {"title" => "Female", "value" => 230, "row_type" => :secondary},
          {"title" => "Transgender", "value" => 6, "row_type" => :secondary},
          {"title" => "Diabetes only", "value" => 504, "row_type" => :header},
          {"title" => "Male", "value" => 250, "row_type" => :secondary},
          {"title" => "Female", "value" => 245, "row_type" => :secondary},
          {"title" => "Transgender", "value" => 9, "row_type" => :secondary},
          {"title" => "Hypertension and diabetes", "value" => 462, "row_type" => :header},
          {"title" => "Male", "value" => 224, "row_type" => :secondary},
          {"title" => "Female", "value" => 230, "row_type" => :secondary},
          {"title" => "Transgender", "value" => 8, "row_type" => :secondary}
        ]
      }

      @ccb_tablets = {
        "name" => "CCB tablets",
        "days_of_drugs_left" => 65,
        "breakdown" => [
          {"title" => "Amlodipine 5 mg OD", "stock" => 100},
          {"title" => "Amlodipine 10 mg", "stock" => 500}
        ]
      }

      @arb_tablets = {
        "name" => "ARB tablets",
        "days_of_drugs_left" => 0,
        "breakdown" => [
          {"title" => "Losartan 50 mg", "stock" => 0},
          {"title" => "Telmisartan 40 mg", "stock" => 0},
          {"title" => "Telmisartan 80 mg", "stock" => 0}
        ]
      }

      @diuretic_tablets = {
        "name" => "Diuretic tablets",
        "days_of_drugs_left" => 0,
        "breakdown" => [
          {"title" => "Chlorthalidone 12.5 mg", "stock" => 0},
          {"title" => "Hydrochlorthiazide 25 mg", "stock" => 0}
        ]
      }

      @hypertension_assigned_patients = {
        "total" => 793,
        "table_breakdown" => [
          {"title" => "Registered patients", "value" => 877},
          {"title" => "Transferred-in", "value" => 3},
          {"title" => "Transferred-out", "value" => -87}
        ],
        "breakdown" =>
          {"numerators" => [11, 11, 12, 12, 12, 12],
           "denominators" => [11, 11, 12, 12, 12, 12],
           "rates" => [11, 11, 12, 12, 12, 12],
           "period_info" => [{name: "Apr-2022",
                              ltfu_since_date: "30-Apr-2021",
                              bp_control_start_date: "1-Feb-2022",
                              bp_control_end_date: "30-Apr-2022",
                              bp_control_registration_date: "31-Jan-2022"},
             {name: "May-2022",
              ltfu_since_date: "31-May-2021",
              bp_control_start_date: "1-Mar-2022",
              bp_control_end_date: "31-May-2022",
              bp_control_registration_date: "28-Feb-2022"},
             {name: "Jun-2022",
              ltfu_since_date: "30-Jun-2021",
              bp_control_start_date: "1-Apr-2022",
              bp_control_end_date: "30-Jun-2022",
              bp_control_registration_date: "31-Mar-2022"},
             {name: "Jul-2022",
              ltfu_since_date: "31-Jul-2021",
              bp_control_start_date: "1-May-2022",
              bp_control_end_date: "31-Jul-2022",
              bp_control_registration_date: "30-Apr-2022"},
             {name: "Aug-2022",
              ltfu_since_date: "31-Aug-2021",
              bp_control_start_date: "1-Jun-2022",
              bp_control_end_date: "31-Aug-2022",
              bp_control_registration_date: "31-May-2022"},
             {name: "Sep-2022", ltfu_since_date: "30-Sep-2021",
              bp_control_start_date: "1-Jul-2022",
              bp_control_end_date: "30-Sep-2022",
              bp_control_registration_date: "30-Jun-2022"}]}
      }

      @hypertension_registered_patients = {
        "data_type" => "number",
        "table_breakdown" => [
          {"title" => "Registered patients", "value" => 877},
          {"title" => "Transferred-in", "value" => 3},
          {"title" => "Transferred-out", "value" => -87}
        ],
        "breakdown" =>
          {"numerators" => [11, 11, 12, 12, 12, 12],
           "denominators" => [11, 11, 12, 12, 12, 12],
           "rates" => [11, 11, 12, 12, 12, 12],
           "period_info" => [{name: "Apr-2022",
                              ltfu_since_date: "30-Apr-2021",
                              bp_control_start_date: "1-Feb-2022",
                              bp_control_end_date: "30-Apr-2022",
                              bp_control_registration_date: "31-Jan-2022"},
             {name: "May-2022",
              ltfu_since_date: "31-May-2021",
              bp_control_start_date: "1-Mar-2022",
              bp_control_end_date: "31-May-2022",
              bp_control_registration_date: "28-Feb-2022"},
             {name: "Jun-2022",
              ltfu_since_date: "30-Jun-2021",
              bp_control_start_date: "1-Apr-2022",
              bp_control_end_date: "30-Jun-2022",
              bp_control_registration_date: "31-Mar-2022"},
             {name: "Jul-2022",
              ltfu_since_date: "31-Jul-2021",
              bp_control_start_date: "1-May-2022",
              bp_control_end_date: "31-Jul-2022",
              bp_control_registration_date: "30-Apr-2022"},
             {name: "Aug-2022",
              ltfu_since_date: "31-Aug-2021",
              bp_control_start_date: "1-Jun-2022",
              bp_control_end_date: "31-Aug-2022",
              bp_control_registration_date: "31-May-2022"},
             {name: "Sep-2022", ltfu_since_date: "30-Sep-2021",
              bp_control_start_date: "1-Jul-2022",
              bp_control_end_date: "30-Sep-2022",
              bp_control_registration_date: "30-Jun-2022"}]}
      }

      @hypertension_monthly_follow_up_patients = {
        "data_type" => "number",
        "table_breakdown" => [
          {"title" => "Registered patients", "value" => 877},
          {"title" => "Transferred-in", "value" => 3},
          {"title" => "Transferred-out", "value" => -87}
        ],
        "breakdown" =>
          {"numerators" => [11, 11, 12, 12, 12, 12],
           "denominators" => [11, 11, 12, 12, 12, 12],
           "rates" => [11, 11, 12, 12, 12, 12],
           "period_info" => [{name: "Apr-2022",
                              ltfu_since_date: "30-Apr-2021",
                              bp_control_start_date: "1-Feb-2022",
                              bp_control_end_date: "30-Apr-2022",
                              bp_control_registration_date: "31-Jan-2022"},
             {name: "May-2022",
              ltfu_since_date: "31-May-2021",
              bp_control_start_date: "1-Mar-2022",
              bp_control_end_date: "31-May-2022",
              bp_control_registration_date: "28-Feb-2022"},
             {name: "Jun-2022",
              ltfu_since_date: "30-Jun-2021",
              bp_control_start_date: "1-Apr-2022",
              bp_control_end_date: "30-Jun-2022",
              bp_control_registration_date: "31-Mar-2022"},
             {name: "Jul-2022",
              ltfu_since_date: "31-Jul-2021",
              bp_control_start_date: "1-May-2022",
              bp_control_end_date: "31-Jul-2022",
              bp_control_registration_date: "30-Apr-2022"},
             {name: "Aug-2022",
              ltfu_since_date: "31-Aug-2021",
              bp_control_start_date: "1-Jun-2022",
              bp_control_end_date: "31-Aug-2022",
              bp_control_registration_date: "31-May-2022"},
             {name: "Sep-2022", ltfu_since_date: "30-Sep-2021",
              bp_control_start_date: "1-Jul-2022",
              bp_control_end_date: "30-Sep-2022",
              bp_control_registration_date: "30-Jun-2022"}]}
      }

      @hypertension_bp_controlled = {
        "data_type" => "percentage",
        "table_breakdown" => [
          {"title" => "Registered patients", "value" => 877},
          {"title" => "Transferred-in", "value" => 3},
          {"title" => "Transferred-out", "value" => -87}
        ],
        "breakdown" =>
          {"numerators" => [11, 11, 12, 12, 12, 12],
           "denominators" => [11, 11, 12, 12, 12, 12],
           "rates" => [11, 11, 12, 12, 12, 12],
           "period_info" => [{name: "Apr-2022",
                              ltfu_since_date: "30-Apr-2021",
                              bp_control_start_date: "1-Feb-2022",
                              bp_control_end_date: "30-Apr-2022",
                              bp_control_registration_date: "31-Jan-2022"},
             {name: "May-2022",
              ltfu_since_date: "31-May-2021",
              bp_control_start_date: "1-Mar-2022",
              bp_control_end_date: "31-May-2022",
              bp_control_registration_date: "28-Feb-2022"},
             {name: "Jun-2022",
              ltfu_since_date: "30-Jun-2021",
              bp_control_start_date: "1-Apr-2022",
              bp_control_end_date: "30-Jun-2022",
              bp_control_registration_date: "31-Mar-2022"},
             {name: "Jul-2022",
              ltfu_since_date: "31-Jul-2021",
              bp_control_start_date: "1-May-2022",
              bp_control_end_date: "31-Jul-2022",
              bp_control_registration_date: "30-Apr-2022"},
             {name: "Aug-2022",
              ltfu_since_date: "31-Aug-2021",
              bp_control_start_date: "1-Jun-2022",
              bp_control_end_date: "31-Aug-2022",
              bp_control_registration_date: "31-May-2022"},
             {name: "Sep-2022", ltfu_since_date: "30-Sep-2021",
              bp_control_start_date: "1-Jul-2022",
              bp_control_end_date: "30-Sep-2022",
              bp_control_registration_date: "30-Jun-2022"}]}
      }

      @hypertension_bp_not_controlled = {
        "data_type" => "percentage",
        "table_breakdown" => [
          {"title" => "Registered patients", "value" => 877},
          {"title" => "Transferred-in", "value" => 3},
          {"title" => "Transferred-out", "value" => -87}
        ],
        "breakdown" =>
          {"numerators" => [11, 11, 12, 12, 12, 12],
           "denominators" => [11, 11, 12, 12, 12, 12],
           "rates" => [11, 11, 12, 12, 12, 12],
           "period_info" => [{name: "Apr-2022",
                              ltfu_since_date: "30-Apr-2021",
                              bp_control_start_date: "1-Feb-2022",
                              bp_control_end_date: "30-Apr-2022",
                              bp_control_registration_date: "31-Jan-2022"},
             {name: "May-2022",
              ltfu_since_date: "31-May-2021",
              bp_control_start_date: "1-Mar-2022",
              bp_control_end_date: "31-May-2022",
              bp_control_registration_date: "28-Feb-2022"},
             {name: "Jun-2022",
              ltfu_since_date: "30-Jun-2021",
              bp_control_start_date: "1-Apr-2022",
              bp_control_end_date: "30-Jun-2022",
              bp_control_registration_date: "31-Mar-2022"},
             {name: "Jul-2022",
              ltfu_since_date: "31-Jul-2021",
              bp_control_start_date: "1-May-2022",
              bp_control_end_date: "31-Jul-2022",
              bp_control_registration_date: "30-Apr-2022"},
             {name: "Aug-2022",
              ltfu_since_date: "31-Aug-2021",
              bp_control_start_date: "1-Jun-2022",
              bp_control_end_date: "31-Aug-2022",
              bp_control_registration_date: "31-May-2022"},
             {name: "Sep-2022", ltfu_since_date: "30-Sep-2021",
              bp_control_start_date: "1-Jul-2022",
              bp_control_end_date: "30-Sep-2022",
              bp_control_registration_date: "30-Jun-2022"}]}
      }

      @hypertension_missed_visits = {
        "data_type" => "percentage",
        "table_breakdown" => [
          {"title" => "Registered patients", "value" => 877},
          {"title" => "Transferred-in", "value" => 3},
          {"title" => "Transferred-out", "value" => -87}
        ],
        "breakdown" =>
          {"numerators" => [11, 11, 12, 12, 12, 12],
           "denominators" => [11, 11, 12, 12, 12, 12],
           "rates" => [11, 11, 12, 12, 12, 12],
           "period_info" => [{name: "Apr-2022",
                              ltfu_since_date: "30-Apr-2021",
                              bp_control_start_date: "1-Feb-2022",
                              bp_control_end_date: "30-Apr-2022",
                              bp_control_registration_date: "31-Jan-2022"},
             {name: "May-2022",
              ltfu_since_date: "31-May-2021",
              bp_control_start_date: "1-Mar-2022",
              bp_control_end_date: "31-May-2022",
              bp_control_registration_date: "28-Feb-2022"},
             {name: "Jun-2022",
              ltfu_since_date: "30-Jun-2021",
              bp_control_start_date: "1-Apr-2022",
              bp_control_end_date: "30-Jun-2022",
              bp_control_registration_date: "31-Mar-2022"},
             {name: "Jul-2022",
              ltfu_since_date: "31-Jul-2021",
              bp_control_start_date: "1-May-2022",
              bp_control_end_date: "31-Jul-2022",
              bp_control_registration_date: "30-Apr-2022"},
             {name: "Aug-2022",
              ltfu_since_date: "31-Aug-2021",
              bp_control_start_date: "1-Jun-2022",
              bp_control_end_date: "31-Aug-2022",
              bp_control_registration_date: "31-May-2022"},
             {name: "Sep-2022", ltfu_since_date: "30-Sep-2021",
              bp_control_start_date: "1-Jul-2022",
              bp_control_end_date: "30-Sep-2022",
              bp_control_registration_date: "30-Jun-2022"}]}
      }

      @hypertension_quarterly_cohort_reports = {
        "data_type" => "percentage",
        "table_breakdown" => [
          {total_patients: 877,
           controlled: 200,
           controlled_rate: 23,
           uncontrolled: 300,
           uncontrolled_rate: 34,
           missed_visits: 177,
           missed_visits_rate: 20,
           visit_no_bp: 200,
           visit_no_bp_rate: 23,
           registration_period: "Q3-2021",
           period: "Q4-2022"},
          {total_patients: 3,
           controlled: 200,
           controlled_rate: 23,
           uncontrolled: 300,
           uncontrolled_rate: 34,
           missed_visits: 177,
           missed_visits_rate: 20,
           visit_no_bp: 200,
           visit_no_bp_rate: 23,
           registration_period: "Q2-2021",
           period: "Q3-2021"},
          {total_patients: 87,
           controlled: 200,
           controlled_rate: 23,
           uncontrolled: 300,
           uncontrolled_rate: 34,
           missed_visits: 177,
           missed_visits_rate: 20,
           visit_no_bpt: 200,
           visit_no_bp_rate: 23,
           registration_period: "Q1-2021",
           period: "Q2-2021"},
          {total_patients: 56,
           controlled: 200,
           controlled_rate: 23,
           uncontrolled: 300,
           uncontrolled_rate: 34,
           missed_visits: 177,
           missed_visits_rate: 20,
           visit_no_bp: 200,
           visit_no_bp_rate: 23,
           registration_period: "Q4-2020",
           period: "Q1-2021"}
        ],
        "breakdown" =>
          {"numerators" => [11, 11, 12, 12, 12, 12],
           "denominators" => [11, 11, 12, 12, 12, 12],
           "rates" => [11, 11, 12, 12, 12, 12],
           "period_info" => [{name: "Apr-2022",
                              ltfu_since_date: "30-Apr-2021",
                              bp_control_start_date: "1-Feb-2022",
                              bp_control_end_date: "30-Apr-2022",
                              bp_control_registration_date: "31-Jan-2022"},
             {name: "May-2022",
              ltfu_since_date: "31-May-2021",
              bp_control_start_date: "1-Mar-2022",
              bp_control_end_date: "31-May-2022",
              bp_control_registration_date: "28-Feb-2022"},
             {name: "Jun-2022",
              ltfu_since_date: "30-Jun-2021",
              bp_control_start_date: "1-Apr-2022",
              bp_control_end_date: "30-Jun-2022",
              bp_control_registration_date: "31-Mar-2022"},
             {name: "Jul-2022",
              ltfu_since_date: "31-Jul-2021",
              bp_control_start_date: "1-May-2022",
              bp_control_end_date: "31-Jul-2022",
              bp_control_registration_date: "30-Apr-2022"},
             {name: "Aug-2022",
              ltfu_since_date: "31-Aug-2021",
              bp_control_start_date: "1-Jun-2022",
              bp_control_end_date: "31-Aug-2022",
              bp_control_registration_date: "31-May-2022"},
             {name: "Sep-2022", ltfu_since_date: "30-Sep-2021",
              bp_control_start_date: "1-Jul-2022",
              bp_control_end_date: "30-Sep-2022",
              bp_control_registration_date: "30-Jun-2022"}]}
      }

      @diabetes_assigned_patients = {
        "total" => 397,
        "table_breakdown" => [
          {"title" => "Registered patients", "value" => 877},
          {"title" => "Transferred-in", "value" => 3},
          {"title" => "Transferred-out", "value" => -87}
        ],
        "breakdown" =>
          {"numerators" => [11, 11, 12, 12, 12, 12],
           "denominators" => [11, 11, 12, 12, 12, 12],
           "rates" => [11, 11, 12, 12, 12, 12],
           "period_info" => [{name: "Apr-2022",
                              ltfu_since_date: "30-Apr-2021",
                              bp_control_start_date: "1-Feb-2022",
                              bp_control_end_date: "30-Apr-2022",
                              bp_control_registration_date: "31-Jan-2022"},
             {name: "May-2022",
              ltfu_since_date: "31-May-2021",
              bp_control_start_date: "1-Mar-2022",
              bp_control_end_date: "31-May-2022",
              bp_control_registration_date: "28-Feb-2022"},
             {name: "Jun-2022",
              ltfu_since_date: "30-Jun-2021",
              bp_control_start_date: "1-Apr-2022",
              bp_control_end_date: "30-Jun-2022",
              bp_control_registration_date: "31-Mar-2022"},
             {name: "Jul-2022",
              ltfu_since_date: "31-Jul-2021",
              bp_control_start_date: "1-May-2022",
              bp_control_end_date: "31-Jul-2022",
              bp_control_registration_date: "30-Apr-2022"},
             {name: "Aug-2022",
              ltfu_since_date: "31-Aug-2021",
              bp_control_start_date: "1-Jun-2022",
              bp_control_end_date: "31-Aug-2022",
              bp_control_registration_date: "31-May-2022"},
             {name: "Sep-2022", ltfu_since_date: "30-Sep-2021",
              bp_control_start_date: "1-Jul-2022",
              bp_control_end_date: "30-Sep-2022",
              bp_control_registration_date: "30-Jun-2022"}]}
      }

      @diabetes_registered_patients = {
        "data_type" => "number",
        "table_breakdown" => [
          {"title" => "Registered patients", "value" => 877},
          {"title" => "Transferred-in", "value" => 3},
          {"title" => "Transferred-out", "value" => -87}
        ],
        "breakdown" =>
          {"numerators" => [11, 11, 12, 12, 12, 12],
           "denominators" => [11, 11, 12, 12, 12, 12],
           "rates" => [11, 11, 12, 12, 12, 12],
           "period_info" => [{name: "Apr-2022",
                              ltfu_since_date: "30-Apr-2021",
                              bp_control_start_date: "1-Feb-2022",
                              bp_control_end_date: "30-Apr-2022",
                              bp_control_registration_date: "31-Jan-2022"},
             {name: "May-2022",
              ltfu_since_date: "31-May-2021",
              bp_control_start_date: "1-Mar-2022",
              bp_control_end_date: "31-May-2022",
              bp_control_registration_date: "28-Feb-2022"},
             {name: "Jun-2022",
              ltfu_since_date: "30-Jun-2021",
              bp_control_start_date: "1-Apr-2022",
              bp_control_end_date: "30-Jun-2022",
              bp_control_registration_date: "31-Mar-2022"},
             {name: "Jul-2022",
              ltfu_since_date: "31-Jul-2021",
              bp_control_start_date: "1-May-2022",
              bp_control_end_date: "31-Jul-2022",
              bp_control_registration_date: "30-Apr-2022"},
             {name: "Aug-2022",
              ltfu_since_date: "31-Aug-2021",
              bp_control_start_date: "1-Jun-2022",
              bp_control_end_date: "31-Aug-2022",
              bp_control_registration_date: "31-May-2022"},
             {name: "Sep-2022", ltfu_since_date: "30-Sep-2021",
              bp_control_start_date: "1-Jul-2022",
              bp_control_end_date: "30-Sep-2022",
              bp_control_registration_date: "30-Jun-2022"}]}
      }

      @diabetes_monthly_follow_up_patients = {
        "data_type" => "number",
        "table_breakdown" => [
          {"title" => "Registered patients", "value" => 877},
          {"title" => "Transferred-in", "value" => 3},
          {"title" => "Transferred-out", "value" => -87}
        ],
        "breakdown" =>
          {"numerators" => [11, 11, 12, 12, 12, 12],
           "denominators" => [11, 11, 12, 12, 12, 12],
           "rates" => [11, 11, 12, 12, 12, 12],
           "period_info" => [{name: "Apr-2022",
                              ltfu_since_date: "30-Apr-2021",
                              bp_control_start_date: "1-Feb-2022",
                              bp_control_end_date: "30-Apr-2022",
                              bp_control_registration_date: "31-Jan-2022"},
             {name: "May-2022",
              ltfu_since_date: "31-May-2021",
              bp_control_start_date: "1-Mar-2022",
              bp_control_end_date: "31-May-2022",
              bp_control_registration_date: "28-Feb-2022"},
             {name: "Jun-2022",
              ltfu_since_date: "30-Jun-2021",
              bp_control_start_date: "1-Apr-2022",
              bp_control_end_date: "30-Jun-2022",
              bp_control_registration_date: "31-Mar-2022"},
             {name: "Jul-2022",
              ltfu_since_date: "31-Jul-2021",
              bp_control_start_date: "1-May-2022",
              bp_control_end_date: "31-Jul-2022",
              bp_control_registration_date: "30-Apr-2022"},
             {name: "Aug-2022",
              ltfu_since_date: "31-Aug-2021",
              bp_control_start_date: "1-Jun-2022",
              bp_control_end_date: "31-Aug-2022",
              bp_control_registration_date: "31-May-2022"},
             {name: "Sep-2022", ltfu_since_date: "30-Sep-2021",
              bp_control_start_date: "1-Jul-2022",
              bp_control_end_date: "30-Sep-2022",
              bp_control_registration_date: "30-Jun-2022"}]}
      }

      @diabetes_lt_200 = {
        "data_type" => "percentage",
        "table_breakdown" => [
          {"title" => "Registered patients", "value" => 877},
          {"title" => "Transferred-in", "value" => 3},
          {"title" => "Transferred-out", "value" => -87}
        ],
        "breakdown" =>
          {"numerators" => [11, 11, 12, 12, 12, 12],
           "denominators" => [11, 11, 12, 12, 12, 12],
           "rates" => [11, 11, 12, 12, 12, 12],
           "period_info" => [{name: "Apr-2022",
                              ltfu_since_date: "30-Apr-2021",
                              bp_control_start_date: "1-Feb-2022",
                              bp_control_end_date: "30-Apr-2022",
                              bp_control_registration_date: "31-Jan-2022"},
             {name: "May-2022",
              ltfu_since_date: "31-May-2021",
              bp_control_start_date: "1-Mar-2022",
              bp_control_end_date: "31-May-2022",
              bp_control_registration_date: "28-Feb-2022"},
             {name: "Jun-2022",
              ltfu_since_date: "30-Jun-2021",
              bp_control_start_date: "1-Apr-2022",
              bp_control_end_date: "30-Jun-2022",
              bp_control_registration_date: "31-Mar-2022"},
             {name: "Jul-2022",
              ltfu_since_date: "31-Jul-2021",
              bp_control_start_date: "1-May-2022",
              bp_control_end_date: "31-Jul-2022",
              bp_control_registration_date: "30-Apr-2022"},
             {name: "Aug-2022",
              ltfu_since_date: "31-Aug-2021",
              bp_control_start_date: "1-Jun-2022",
              bp_control_end_date: "31-Aug-2022",
              bp_control_registration_date: "31-May-2022"},
             {name: "Sep-2022", ltfu_since_date: "30-Sep-2021",
              bp_control_start_date: "1-Jul-2022",
              bp_control_end_date: "30-Sep-2022",
              bp_control_registration_date: "30-Jun-2022"}]}
      }

      @diabetes_200_299 = {
        "data_type" => "percentage",
        "table_breakdown" => [
          {"title" => "Registered patients", "value" => 877},
          {"title" => "Transferred-in", "value" => 3},
          {"title" => "Transferred-out", "value" => -87}
        ],
        "breakdown" =>
          {"numerators" => [11, 11, 12, 12, 12, 12],
           "denominators" => [11, 11, 12, 12, 12, 12],
           "rates" => [11, 11, 12, 12, 12, 12],
           "period_info" => [{name: "Apr-2022",
                              ltfu_since_date: "30-Apr-2021",
                              bp_control_start_date: "1-Feb-2022",
                              bp_control_end_date: "30-Apr-2022",
                              bp_control_registration_date: "31-Jan-2022"},
             {name: "May-2022",
              ltfu_since_date: "31-May-2021",
              bp_control_start_date: "1-Mar-2022",
              bp_control_end_date: "31-May-2022",
              bp_control_registration_date: "28-Feb-2022"},
             {name: "Jun-2022",
              ltfu_since_date: "30-Jun-2021",
              bp_control_start_date: "1-Apr-2022",
              bp_control_end_date: "30-Jun-2022",
              bp_control_registration_date: "31-Mar-2022"},
             {name: "Jul-2022",
              ltfu_since_date: "31-Jul-2021",
              bp_control_start_date: "1-May-2022",
              bp_control_end_date: "31-Jul-2022",
              bp_control_registration_date: "30-Apr-2022"},
             {name: "Aug-2022",
              ltfu_since_date: "31-Aug-2021",
              bp_control_start_date: "1-Jun-2022",
              bp_control_end_date: "31-Aug-2022",
              bp_control_registration_date: "31-May-2022"},
             {name: "Sep-2022", ltfu_since_date: "30-Sep-2021",
              bp_control_start_date: "1-Jul-2022",
              bp_control_end_date: "30-Sep-2022",
              bp_control_registration_date: "30-Jun-2022"}]}
      }

      @diabetes_ge_300 = {
        "data_type" => "percentage",
        "table_breakdown" => [
          {"title" => "Registered patients", "value" => 877},
          {"title" => "Transferred-in", "value" => 3},
          {"title" => "Transferred-out", "value" => -87}
        ],
        "breakdown" =>
          {"numerators" => [11, 11, 12, 12, 12, 12],
           "denominators" => [11, 11, 12, 12, 12, 12],
           "rates" => [11, 11, 12, 12, 12, 12],
           "period_info" => [{name: "Apr-2022",
                              ltfu_since_date: "30-Apr-2021",
                              bp_control_start_date: "1-Feb-2022",
                              bp_control_end_date: "30-Apr-2022",
                              bp_control_registration_date: "31-Jan-2022"},
             {name: "May-2022",
              ltfu_since_date: "31-May-2021",
              bp_control_start_date: "1-Mar-2022",
              bp_control_end_date: "31-May-2022",
              bp_control_registration_date: "28-Feb-2022"},
             {name: "Jun-2022",
              ltfu_since_date: "30-Jun-2021",
              bp_control_start_date: "1-Apr-2022",
              bp_control_end_date: "30-Jun-2022",
              bp_control_registration_date: "31-Mar-2022"},
             {name: "Jul-2022",
              ltfu_since_date: "31-Jul-2021",
              bp_control_start_date: "1-May-2022",
              bp_control_end_date: "31-Jul-2022",
              bp_control_registration_date: "30-Apr-2022"},
             {name: "Aug-2022",
              ltfu_since_date: "31-Aug-2021",
              bp_control_start_date: "1-Jun-2022",
              bp_control_end_date: "31-Aug-2022",
              bp_control_registration_date: "31-May-2022"},
             {name: "Sep-2022", ltfu_since_date: "30-Sep-2021",
              bp_control_start_date: "1-Jul-2022",
              bp_control_end_date: "30-Sep-2022",
              bp_control_registration_date: "30-Jun-2022"}]}
      }

      @diabetes_missed_visits = {
        "data_type" => "percentage",
        "table_breakdown" => [
          {"title" => "Registered patients", "value" => 877},
          {"title" => "Transferred-in", "value" => 3},
          {"title" => "Transferred-out", "value" => -87}
        ],
        "breakdown" =>
          {"numerators" => [11, 11, 12, 12, 12, 12],
           "denominators" => [11, 11, 12, 12, 12, 12],
           "rates" => [11, 11, 12, 12, 12, 12],
           "period_info" => [{name: "Apr-2022",
                              ltfu_since_date: "30-Apr-2021",
                              bp_control_start_date: "1-Feb-2022",
                              bp_control_end_date: "30-Apr-2022",
                              bp_control_registration_date: "31-Jan-2022"},
             {name: "May-2022",
              ltfu_since_date: "31-May-2021",
              bp_control_start_date: "1-Mar-2022",
              bp_control_end_date: "31-May-2022",
              bp_control_registration_date: "28-Feb-2022"},
             {name: "Jun-2022",
              ltfu_since_date: "30-Jun-2021",
              bp_control_start_date: "1-Apr-2022",
              bp_control_end_date: "30-Jun-2022",
              bp_control_registration_date: "31-Mar-2022"},
             {name: "Jul-2022",
              ltfu_since_date: "31-Jul-2021",
              bp_control_start_date: "1-May-2022",
              bp_control_end_date: "31-Jul-2022",
              bp_control_registration_date: "30-Apr-2022"},
             {name: "Aug-2022",
              ltfu_since_date: "31-Aug-2021",
              bp_control_start_date: "1-Jun-2022",
              bp_control_end_date: "31-Aug-2022",
              bp_control_registration_date: "31-May-2022"},
             {name: "Sep-2022", ltfu_since_date: "30-Sep-2021",
              bp_control_start_date: "1-Jul-2022",
              bp_control_end_date: "30-Sep-2022",
              bp_control_registration_date: "30-Jun-2022"}]}
      }
    end

    def period_reports
      {
        "daily_periods" => @daily_periods,
        "daily_registered_patients" => @daily_registered_patients,
        "daily_follow_up_patients" => @daily_follow_up_patients,
        "monthly_periods" => @monthly_periods,
        "monthly_registered_patients" => @monthly_registered_patients,
        "monthly_follow_up_patients" => @monthly_follow_up_patients,
        "yearly_periods" => @yearly_periods,
        "yearly_registered_patients" => @yearly_registered_patients,
        "yearly_follow_up_patients" => @yearly_follow_up_patients
      }
    end

    def hypertension_reports
      {
        "assigned_patients" => @hypertension_assigned_patients,
        "registered_patients" => @hypertension_registered_patients,
        "monthly_follow_up_patients" => @hypertension_monthly_follow_up_patients,
        "controlled" => @hypertension_bp_controlled,
        "uncontrolled" => @hypertension_bp_not_controlled,
        "missed_visits" => @hypertension_missed_visits,
        "quarterly_cohort_reports" => @hypertension_quarterly_cohort_reports,
        "ccb_tablets" => @ccb_tablets,
        "arb_tablets" => @arb_tablets,
        "diuretic_tablets" => @diuretic_tablets
      }
    end

    def diabetes_reports
      {
        "assigned_patients" => @diabetes_assigned_patients,
        "registered_patients" => @diabetes_registered_patients,
        "monthly_follow_up_patients" => @diabetes_monthly_follow_up_patients,
        "controlled" => @diabetes_lt_200,
        "uncontrolled" => @diabetes_200_299,
        "very_uncontrolled" => @diabetes_ge_300,
        "missed_visits" => @diabetes_missed_visits
      }
    end
  end
end
