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
    reporting_dates(2021, 6)
  end

  def reporting_dates(year = Date.today.year, month = Date.today.month)
    # We explicitly set the times in the reporting TZ here, but don't use the block helper because its a hassle w/
    # all the local vars we need
    timezone = Time.find_zone(Period::REPORTING_TIME_ZONE)
    now = timezone.local(year, month, 1, 0, 0, 0) # Beginning of the month
    {
      now: now,
      long_ago: now - 5.years,
      under_12_months_ago: timezone.local(year - 1, month + 1, 1, 0, 0, 1),
      over_12_months_ago: now - 11.months - 1.second,
      month_string: "#{year}-#{"%02d" % month}",
      beginning_of_month: now,
      over_3_months_ago: now - 2.months - 1.day,
      under_3_months_ago: now - 2.months,
      end_of_month: now + 1.month - 1.second,
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
    month_date = timezone.local(Date.today.year, Date.today.month, 1, 0, 0, 0) # Beginning of the month
    {
      month: month_date,
      long_ago: month_date - 5.years,
      month_string: "2021-06",
      beginning_of_month: month_date, # Beginning of current month
      over_3_months_ago: timezone.local(2021, 3, 31, 0, 0, 0),
      under_3_months_ago: timezone.local(2021, 4, 1, 0, 0, 0),
      end_of_month: timezone.local(2021, 6, 30, 23, 59, 59), # End of current month
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
