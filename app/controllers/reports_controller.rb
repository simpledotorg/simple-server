class ReportsController < AdminController
  layout "reports"
  skip_after_action :verify_policy_scoped
  around_action :set_time_zone

  def index
    authorize :dashboard, :view_my_facilities?

    @state_name = "Punjab"
    @district_name = "Bathinda"
    @report_period = "APR-2020"
    @last_updated = "28-MAY-2020"
    # 20% Bathinda population
    @hypertensive_population = 277705
    @controlled_patients = {
      "Jan 2018" => 59,
      "Feb 2018" => 154,
      "Mar 2018" => 239,
      "Apr 2018" => 329,
      "May 2018" => 331,
      "Jun 2018" => 378,
      "Jul 2018" => 468,
      "Aug 2018" => 547,
      "Sep 2018" => 678,
      "Oct 2018" => 684,
      "Nov 2018" => 763,
      "Dec 2018" => 705,
      "Jan 2019" => 867,
      "Feb 2019" => 1153,
      "Mar 2019" => 1518,
      "Apr 2019" => 1850,
      "May 2019" => 2149,
      "Jun 2019" => 2366,
      "Jul 2019" => 2622,
      "Aug 2019" => 2782,
      "Sep 2019" => 3541,
      "Oct 2019" => 3675,
      "Nov 2019" => 3766,
      "Dec 2019" => 3596,
      "Jan 2020" => 3746,
      "Feb 2020" => 4515,
      "Mar 2020" => 5239,
      "Apr 2020" => 5452
    }
    @control_rate = {
      "Jan 2018" => 10,
      "Feb 2018" => 12,
      "Mar 2018" => 15,
      "Apr 2018" => 17,
      "May 2018" => 16,
      "Jun 2018" => 17,
      "Jul 2018" => 19,
      "Aug 2018" => 20,
      "Sep 2018" => 23,
      "Oct 2018" => 20,
      "Nov 2018" => 19,
      "Dec 2018" => 15,
      "Jan 2019" => 16,
      "Feb 2019" => 17,
      "Mar 2019" => 19,
      "Apr 2019" => 22,
      "May 2019" => 23,
      "Jun 2019" => 24,
      "Jul 2019" => 24,
      "Aug 2019" => 25,
      "Sep 2019" => 29,
      "Oct 2019" => 28,
      "Nov 2019" => 27,
      "Dec 2019" => 24,
      "Jan 2020" => 23,
      "Feb 2020" => 26,
      "Mar 2020" => 29,
      "Apr 2020" => 29
    }
    @registrations = {
      "Jan 2018" => 606,
      "Feb 2018" => 1282,
      "Mar 2018" => 1636,
      "Apr 2018" => 1919,
      "May 2018" => 2112,
      "Jun 2018" => 2239,
      "Jul 2018" => 2468,
      "Aug 2018" => 2732,
      "Sep 2018" => 2955,
      "Oct 2018" => 3354,
      "Nov 2018" => 3994,
      "Dec 2018" => 4726,
      "Jan 2019" => 5537,
      "Feb 2019" => 6653,
      "Mar 2019" => 7808,
      "Apr 2019" => 8587,
      "May 2019" => 9431,
      "Jun 2019" => 9998,
      "Jul 2019" => 10725,
      "Aug 2019" => 11308,
      "Sep 2019" => 12223,
      "Oct 2019" => 13092,
      "Nov 2019" => 14027,
      "Dec 2019" => 15174,
      "Jan 2020" => 16218,
      "Feb 2020" => 17450,
      "Mar 2020" => 18223,
      "Apr 2020" => 18587
    }
    @quarterly_registrations = [
      {
        "results_in" => "Q2-2020",
        "patients_registered" => "Q1-2020",
        "cohort_trend" => [
          {
            "period" => "Dec 2019",
            "registered" => 1147,
            "no_bp" => {
              "total" => 413,
              "percent" => 36
            },
            "uncontrolled" => {
              "total" => 286,
              "percent" => 25
            },
            "controlled" => {
              "total" => 448,
              "percent" => 39
            }
          },
          {
            "period" => "Nov 2019",
            "registered" => 934,
            "no_bp" => {
              "total" => 448,
              "percent" => 48
            },
            "uncontrolled" => {
              "total" => 262,
              "percent" => 28
            },
            "controlled" => {
              "total" => 224,
              "percent" => 24
            }
          },
          {
            "period" => "Oct 2019",
            "registered" => 866,
            "no_bp" => {
              "total" => 416,
              "percent" => 48
            },
            "uncontrolled" => {
              "total" => 242,
              "percent" => 28
            },
            "controlled" => {
              "total" => 208,
              "percent" => 24
            }
          }
        ]
      },
      {
        "results_in" => "Q1-2020",
        "patients_registered" => "Q4-2019",
        "cohort_trend" => [
          {
            "period" => "Mar 2020",
            "registered" => 773,
            "no_bp" => {
              "total" => 402,
              "percent" => 52
            },
            "uncontrolled" => {
              "total" => 77,
              "percent" => 10
            },
            "controlled" => {
              "total" => 294,
              "percent" => 38
            }
          },
          {
            "period" => "Feb 2020",
            "registered" => 1232,
            "no_bp" => {
              "total" => 567,
              "percent" => 46
            },
            "uncontrolled" => {
              "total" => 172,
              "percent" => 14
            },
            "controlled" => {
              "total" => 493,
              "percent" => 40
            }
          },
          {
            "period" => "Jan 2020",
            "registered" => 1043,
            "no_bp" => {
              "total" => 407,
              "percent" => 39
            },
            "uncontrolled" => {
              "total" => 208,
              "percent" => 20
            },
            "controlled" => {
              "total" => 428,
              "percent" => 41
            }
          }
        ]
      },
      {
        "results_in" => "Q4-2019",
        "patients_registered" => "Q3-2019",
        "cohort_trend" => [
          {
            "period" => "Dec 2019",
            "registered" => 1147,
            "no_bp" => {
              "total" => 413,
              "percent" => 54
            },
            "uncontrolled" => {
              "total" => 286,
              "percent" => 26
            },
            "controlled" => {
              "total" => 448,
              "percent" => 20
            }
          },
          {
            "period" => "Nov 2019",
            "registered" => 934,
            "no_bp" => {
              "total" => 448,
              "percent" => 48
            },
            "uncontrolled" => {
              "total" => 262,
              "percent" => 28
            },
            "controlled" => {
              "total" => 224,
              "percent" => 24
            }
          },
          {
            "period" => "Oct 2019",
            "registered" => 866,
            "no_bp" => {
              "total" => 416,
              "percent" => 48
            },
            "uncontrolled" => {
              "total" => 242,
              "percent" => 28
            },
            "controlled" => {
              "total" => 208,
              "percent" => 24
            }
          }
        ]
      },
      {
        "results_in" => "Q3-2019",
        "patients_registered" => "Q2-2019",
        "cohort_trend" => [
          {
            "period" => "Mar 2020",
            "registered" => 773,
            "no_bp" => {
              "total" => 402,
              "percent" => 55
            },
            "uncontrolled" => {
              "total" => 77,
              "percent" => 18
            },
            "controlled" => {
              "total" => 294,
              "percent" => 27
            }
          },
          {
            "period" => "Feb 2020",
            "registered" => 1232,
            "no_bp" => {
              "total" => 567,
              "percent" => 46
            },
            "uncontrolled" => {
              "total" => 172,
              "percent" => 14
            },
            "controlled" => {
              "total" => 493,
              "percent" => 40
            }
          },
          {
            "period" => "Jan 2020",
            "registered" => 1043,
            "no_bp" => {
              "total" => 407,
              "percent" => 39
            },
            "uncontrolled" => {
              "total" => 208,
              "percent" => 20
            },
            "controlled" => {
              "total" => 428,
              "percent" => 41
            }
          }
        ]
      }
    ]
  end

  private

  def set_time_zone
    time_zone = Rails.application.config.country[:time_zone] || DEFAULT_ANALYTICS_TIME_ZONE

    Time.use_zone(time_zone) { yield }
  end
end
