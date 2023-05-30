module ReportingHelpers
  def freeze_time_for_reporting_specs(example, date = "June 30 2021 23:00 IST")
    # We need to enforce a known time for these tests, otherwise we will have intermittent failures. For example,
    # if we use live system time, many of these specs will fail after 18:30 UTC (ie 14:30 ET) when on the last day of a month,
    # because that falls into the next day in IST (our reporting time zone). So to prevent confusing failures for
    # developers or CI during North American afternoons, we freeze to a time that will be the end of the month for
    # UTC, ET, and IST. Timezones! 🤯
    Timecop.freeze(date) do
      example.run
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
      end_of_month: timezone.local(2021, 6, 30, 23, 59, 59), # End of June 30 2021
      two_years_ago: now - 2.years,
      twelve_months_ago: now - 12.months,
      eleven_months_ago: now - 11.months,
      ten_months_ago: now - 10.months,
      nine_months_ago: now - 9.months,
      eight_months_ago: now - 8.months,
      seven_months_ago: now - 7.months,
      six_months_ago: now - 6.months,
      five_months_ago: now - 5.months,
      four_months_ago: now - 4.months,
      three_months_ago: now - 3.months,
      two_months_ago: now - 2.months,
      one_month_ago: now - 1.month
    }
  end

  def today
    timezone = Time.find_zone(Period::REPORTING_TIME_ZONE)
    year = Date.today.year
    month = Date.today.month
    month_date = timezone.local(year, month, 1, 0, 0, 0) # Beginning of the month
    {
      month: month_date,
      long_ago: month_date - 5.years,
      month_string: "#{year}-#{"%02d" % month}",
      under_12_months_ago: timezone.local(year - 1, month + 1, 1, 0, 0, 1),
      over_12_months_ago: timezone.local(year - 1, month + 1, 1, 0, 0, 1) - 1.second,
      beginning_of_month: month_date, # Beginning of current month
      end_of_month: timezone.local(2021, 6, 30, 23, 59, 59), # End of current month
      under_3_months_ago: timezone.local(year, month - 2, 1, 0, 0, 0),
      over_3_months_ago: timezone.local(year, month - 2, 1, 0, 0, 0) - 1.second,
      two_years_ago: month_date - 2.years,
      twelve_months_ago: month_date - 12.months,
      eleven_months_ago: month_date - 11.months,
      ten_months_ago: month_date - 10.months,
      nine_months_ago: month_date - 9.months,
      eight_months_ago: month_date - 8.months,
      seven_months_ago: month_date - 7.months,
      six_months_ago: month_date - 6.months,
      five_months_ago: month_date - 5.months,
      four_months_ago: month_date - 4.months,
      three_months_ago: month_date - 3.months,
      two_months_ago: month_date - 2.months,
      one_month_ago: month_date - 1.month
    }
  end
end
