class MedicationsDispensationQuery
  BUCKETS = [
    {lower_limit: 0, upper_limit: 14, name: "0-14 days"},
    {lower_limit: 15, upper_limit: 30, name: "15-30 days"},
    {lower_limit: 31, upper_limit: 60, name: "31-60 days"},
    {lower_limit: 61, name: "60+ days"}
  ]
  BUCKET_NAMES = BUCKETS.map { |bucket| bucket[:name] }

  def initialize(region:, previous_periods: 2)
    @region = region
    previous_periods = previous_periods
    current_period = Period.month(Time.current)
    @periods = (current_period.advance(months: -previous_periods)..current_period)
  end

  attr_reader :region, :periods

  # number of appointments by scheduled after by month
  #
  def empty_results
    BUCKET_NAMES.map do |bucket|
      [bucket, {
        percentage: @periods.map { |period| [period, 0] }.to_h,
        number_of_follow_ups: @periods.map { |period| [period, 0] }.to_h
      }]
    end.to_h
  end

  def bucket(days)
    BUCKETS.each do |bucket|
      if days >= bucket[:lower_limit] && (bucket[:upper_limit].nil? || days <= bucket[:upper_limit])
        return bucket[:name]
      end
    end
  end

  def total_follow_ups_per_month(results)
    totals = Hash.new(0)
    results.each do |key, value|
      totals[key.second] += value
    end
  end

  def distribution_by_days
    results = Appointment.where("device_created_at > ?", @periods.begin.to_date).
      group("extract('days' from (scheduled_date - device_created_at))").
      group_by_period(:month, :device_created_at, {format: Period.formatter(:month)}).
      count

    result = empty_results
    results.each_with_object(result) do |(key, value), data|
      days = key.first
      month = key.second
      count = value

      data[bucket(days)][:number_of_follow_ups][month] += count.to_i
    end

    totals = total_follow_ups_per_month(results)

    BUCKETS.each do |bucket|
      periods.each do |period|
        result[bucket][:percentage][period] =
          if totals[period] == 0
            0
          else
            ((result[bucket][:number_of_follow_ups][period] / totals[period].to_f) * 100).round(0)
          end
      end
    end
    result
  end
end
