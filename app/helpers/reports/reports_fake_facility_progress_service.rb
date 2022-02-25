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
        "breakdown" => [
          {"title" => "Registered patients", "value" => 877},
          {"title" => "Transferred-in", "value" => 3},
          {"title" => "Transferred-out", "value" => -87}
        ]
      }

      @hypertension_registered_patients = {
        "data_type" => "number",
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
        "data_type" => "number",
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
        "data_type" => "percentage",
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
        "data_type" => "percentage",
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
        "data_type" => "percentage",
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
        "data_type" => "percentage",
        "breakdown" => [
          {
            "start_period" => "Q4-2021",
            "end_period" => "Q1-2022",
            "registration_period" => "Q3-2021",
            "total_patients" => 227,
            "bp_controlled_rate" => 42,
            "bp_controlled_patients" => 95,
            "bp_not_controlled_rate" => 28,
            "bp_not_controlled_patients" => 64,
            "missed_visits_rate" => 29,
            "missed_visits_patients" => 67
          },
          {
            "start_period" => "Q3-2021",
            "end_period" => "Q4-2021",
            "registration_period" => "Q2-2021",
            "total_patients" => 207,
            "bp_controlled_rate" => 50,
            "bp_controlled_patients" => 104,
            "bp_not_controlled_rate" => 48,
            "bp_not_controlled_patients" => 99,
            "missed_visits_rate" => 2,
            "missed_visits_patients" => 4
          },
          {
            "start_period" => "Q2-2021",
            "end_period" => "Q3-2021",
            "registration_period" => "Q1-2021",
            "total_patients" => 247,
            "bp_controlled_rate" => 42,
            "bp_controlled_patients" => 104,
            "bp_not_controlled_rate" => 26,
            "bp_not_controlled_patients" => 64,
            "missed_visits_rate" => 31,
            "missed_visits_patients" => 79
          },
          {
            "start_period" => "Q1-2021",
            "end_period" => "Q2-2021",
            "registration_period" => "Q4-2020",
            "total_patients" => 198,
            "bp_controlled_rate" => 37,
            "bp_controlled_patients" => 73,
            "bp_not_controlled_rate" => 24,
            "bp_not_controlled_patients" => 48,
            "missed_visits_rate" => 39,
            "missed_visits_patients" => 77
          }
        ]
      }

      @diabetes_assigned_patients = {
        "total" => 397,
        "breakdown" => [
          {"title" => "Registered patients", "value" => 423},
          {"title" => "Transferred-in", "value" => 16},
          {"title" => "Transferred-out", "value" => -42}
        ]
      }

      @diabetes_registered_patients = {
        "data_type" => "number",
        "breakdown" => [
          {"month" => "Aug-2021", "value" => 278},
          {"month" => "Sep-2021", "value" => 290},
          {"month" => "Oct-2021", "value" => 315},
          {"month" => "Nov-2021", "value" => 360},
          {"month" => "Dec-2021", "value" => 380},
          {"month" => "Jan-2022", "value" => 423}
        ]
      }

      @diabetes_monthly_follow_up_patients = {
        "data_type" => "number",
        "breakdown" => [
          {"month" => "Aug-2021", "value" => 103},
          {"month" => "Sep-2021", "value" => 96},
          {"month" => "Oct-2021", "value" => 85},
          {"month" => "Nov-2021", "value" => 120},
          {"month" => "Dec-2021", "value" => 137},
          {"month" => "Jan-2022", "value" => 97}
        ]
      }

      @diabetes_lt_200 = {
        "data_type" => "percentage",
        "breakdown" => [
          {
            "month" => "Aug-2021",
            "value" => 31,
            "period_start" => "Jun-2021",
            "period_end" => "Aug-2021",
            "registration_period" => "May-2021",
            "total_patients" => 112,
            "registered_patients" => 363
          },
          {
            "month" => "Sep-2021",
            "value" => 32,
            "period_start" => "Jul-2021",
            "period_end" => "Sep-2021",
            "registration_period" => "Jun-2021",
            "total_patients" => 112,
            "registered_patients" => 350
          },
          {
            "month" => "Oct-2021",
            "value" => 34,
            "period_start" => "Aug-2021",
            "period_end" => "Oct-2021",
            "registration_period" => "Jul-2021",
            "total_patients" => 163,
            "registered_patients" => 478
          },
          {
            "month" => "Nov-2021",
            "value" => 39,
            "period_start" => "Sep-2021",
            "period_end" => "Nov-2021",
            "registration_period" => "Aug-2021",
            "total_patients" => 189,
            "registered_patients" => 485
          },
          {
            "month" => "Dec-2021",
            "value" => 44,
            "period_start" => "Oct-2021",
            "period_end" => "Dec-2021",
            "registration_period" => "Sep-2021",
            "total_patients" => 242,
            "registered_patients" => 550
          },
          {
            "month" => "Jan-2022",
            "value" => 37,
            "period_start" => "Nov-2021",
            "period_end" => "Jan-2022",
            "registration_period" => "Oct-2021",
            "total_patients" => 197,
            "registered_patients" => 532
          }
        ]
      }

      @diabetes_200_299 = {
        "data_type" => "percentage",
        "breakdown" => [
          {
            "month" => "Aug-2021",
            "value" => 47,
            "period_start" => "Jun-2021",
            "period_end" => "Aug-2021",
            "registration_period" => "May-2021",
            "total_patients" => 116,
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

      @diabetes_ge_300 = {
        "data_type" => "percentage",
        "breakdown" => [
          {
            "month" => "Aug-2021",
            "value" => 8,
            "period_start" => "Jun-2021",
            "period_end" => "Aug-2021",
            "registration_period" => "May-2021",
            "total_patients" => 29,
            "registered_patients" => 363
          },
          {
            "month" => "Sep-2021",
            "value" => 9,
            "period_start" => "Jul-2021",
            "period_end" => "Sep-2021",
            "registration_period" => "Jun-2021",
            "total_patients" => 32,
            "registered_patients" => 350
          },
          {
            "month" => "Oct-2021",
            "value" => 4,
            "period_start" => "Aug-2021",
            "period_end" => "Oct-2021",
            "registration_period" => "Jul-2021",
            "total_patients" => 19,
            "registered_patients" => 478
          },
          {
            "month" => "Nov-2021",
            "value" => 14,
            "period_start" => "Sep-2021",
            "period_end" => "Nov-2021",
            "registration_period" => "Aug-2021",
            "total_patients" => 68,
            "registered_patients" => 485
          },
          {
            "month" => "Dec-2021",
            "value" => 17,
            "period_start" => "Oct-2021",
            "period_end" => "Dec-2021",
            "registration_period" => "Sep-2021",
            "total_patients" => 94,
            "registered_patients" => 550
          },
          {
            "month" => "Jan-2022",
            "value" => 10,
            "period_start" => "Nov-2021",
            "period_end" => "Jan-2022",
            "registration_period" => "Oct-2021",
            "total_patients" => 53,
            "registered_patients" => 532
          }
        ]
      }

      @diabetes_missed_visits = {
        "data_type" => "percentage",
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
