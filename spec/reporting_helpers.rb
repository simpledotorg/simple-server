module ReportingHelpers
  def with_reporting_time_zones(&blk)
    Time.use_zone(Period::REPORTING_TIME_ZONE) do
      Groupdate.time_zone = Period::REPORTING_TIME_ZONE
      blk.call
      Groupdate.time_zone = nil
    end
  end

  def june_2021
    # We explicitly set the times in the reporting TZ here, but don't use the block helper because its a hassle w/
    # all the local vars we need
    timezone = Time.find_zone(Period::REPORTING_TIME_ZONE)
    now = timezone.local(2021, 6, 1, 0, 0, 0)
    {
      now: now,
      long_ago: now - 5.years,
      under_12_months_ago: timezone.local(2020, 7, 1, 0, 0, 1), # Beginning of July 1 2020
      over_12_months_ago: timezone.local(2020, 6, 30, 23, 59, 59), # End of June 30 2020
      month_string: "2021-06",
      beginning_of_month: now, # Beginning of June 1 2021
      over_3_months_ago: timezone.local(2021, 3, 31, 0, 0, 0), # End of March 2021
      under_3_months_ago: timezone.local(2021, 4, 1, 0, 0, 0), # Beginning of April 2021
      end_of_month: timezone.local(2021, 6, 30, 23, 59, 59) # End of June 30 2021
    }
  end
end
