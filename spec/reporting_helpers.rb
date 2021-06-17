module ReportingHelpers
  def with_reporting_time_zones(&blk)
    Time.use_zone(Period::REPORTING_TIME_ZONE) do
      Groupdate.time_zone = Period::REPORTING_TIME_ZONE
      blk.call
      Groupdate.time_zone = nil
    end
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
      month_string: "2021-06",
      beginning_of_month: now, # Beginning of June 1 2021
      over_three_months_ago: timezone.local(2021, 3, 31, 0, 0, 0), # End of March 2021
      under_three_months_ago: timezone.local(2021, 4, 1, 0, 0, 0), # Beginning of April 2021
      end_of_month: timezone.local(2021, 6, 30, 23, 59, 59) # End of June 30 2021
    }
    # Reference chart:
    # 11 july
    # 10 august
    # 9 september
    # 8 october
    # 7 november
    # 6 december
    # 5 january
    # 4 february
    # 3 march
    # 2 april
    # 1 may
    # 0 june
  end
end
