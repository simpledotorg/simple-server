class MedicationsDispensationQuery
  def distribution_by_days
    months = -2
    period = Period.month(Time.current)
    periods = (period.advance(months: months)..period)
    buckets = [0, 15, 31, 60]

    bucketed_records = Appointment
      .select("width_bucket(extract('days' FROM (scheduled_date - device_created_at))::integer, array#{buckets}) bucket_number,
               to_char(device_created_at, 'MM-YYYY') month_name,
               count(*) count")
      .group("bucket_number", "month_name")
      .order("bucket_number")

    pp bucketed_records

    x = bucketed_records.each_with_object({}) do |record, result|
      result[record.bucket_number] ||= {}
      result[record.bucket_number][record.month_name] = record.count
    end

    y = bucketed_records.each_with_object({}) do |record, result|
      result[record.month_name] ||= 0
      result[record.month_name] += record.count
    end
  end

  # {Oct=> {0-14 => count}}
  # {0-14=> {Dec => count}}
  # {[0-14, Dec] => count}}
  #
  # {0-14 => { percentages: {oct: , nov:, dec:},
  #             numbers: {oct: , nov:, dec:}}}

  def distribution_by_days_v2
    results = Appointment.where("device_created_at > ?", 2.months.ago.beginning_of_month).
      group("extract('days' from (scheduled_date - device_created_at))").
      group_by_period(:month, :device_created_at, {format: Period.formatter(:month)}).
      count
    months = -2
    period = Period.month(Time.current)
    periods = (period.advance(months: months)..period)
    buckets = ["0-14 days", "15-30 days", "31-60 days", "60+ days"]
    blank_data = {}
    buckets.each do |bucket|
      periods.each do |period|
        blank_data[bucket] ||= {}
        blank_data[bucket][:percentage] ||= {}
        blank_data[bucket][:number_of_follow_ups] ||= {}
        blank_data[bucket][:percentage][period] = 0
        blank_data[bucket][:number_of_follow_ups][period] = 0
      end
    end

    totals = Hash.new(0)
    results.each do |key, value|
      totals[key.second] += value
    end

    results.inject(blank_data) do |data, (key, value)|
      days = key.first
      month = key.second
      count = value
      pp days
      bucket_name = case
                      when (days >= 0 && days <= 14)
                        "0-14 days"
                      when (days >= 15 && days <= 30)
                        "15-30 days"
                      when (days >= 31 && days <= 60)
                        "31-60 days"
                      when (days > 60)
                        "60+ days"
                    end

      data[bucket_name][:number_of_follow_ups][month] += count.to_i
      data
    end

    buckets.each do |bucket|
      periods.each do |period|
        blank_data[bucket][:percentage][period] =
          if totals[period] == 0
            0
          else
            ((blank_data[bucket][:number_of_follow_ups][period] / totals[period].to_f) * 100).round(0)
          end
      end
    end

    pp "hello"
    pp blank_data
    blank_data
  end
end
