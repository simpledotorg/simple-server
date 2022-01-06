# frozen_string_literal: true

module SQLHelpers
  #
  # This is useful for breaking up the recording time in various time-periods in SQL.
  # It takes the recorded_at (timestamp without timezone) and truncates it to the beginning of the month.
  #
  # Following is the series of transformations it applies to truncate it in right timezone:
  #
  # * Interpret the "timestamp without timezone" in the DB timezone (UTC).
  # * Converts it to a "timestamp with timezone" the country timezone.
  # * Truncates it to a month (this returns a "timestamp without timezone")
  # * Converts it back to a "timestamp with timezone" in the country timezone
  #
  # FAQ:
  #
  # Q. Why should we cast the truncate into a timestamp with timezone at all? Don't we just end up with day/month?
  #
  # A. DATE_TRUNC returns a "timestamp without timezone" not a month/day/quarter. If it's used in a "where"
  # clause for comparison, the timezone will come into effect and is valuable to be kept correct so as to not run into
  # time-period-boundary issues.
  #
  # Usage:
  # BloodPressure.date_to_period_sql('blood_pressures.recorded_at', :month)
  #
  def date_to_period_sql(time_col_with_model_name, period)
    tz = Time.zone.name
    "(DATE_TRUNC('#{period}', (#{time_col_with_model_name}::timestamptz) AT TIME ZONE '#{tz}')) AT TIME ZONE '#{tz}'"
  end
end
