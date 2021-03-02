module Reports
  class Result
    PERCENTAGE_PRECISION = 0

    def initialize(region:, period_type:, data: nil)
      @region = region
      @period_type = period_type
      @quarterly_report = @period_type == :quarter
      @current_period = if quarterly_report?
        Period.quarter(Quarter.current)
      else
        Period.month(Date.current.beginning_of_month)
      end
      @data = data ||
        {
          adjusted_registrations: Hash.new(0),
          adjusted_registrations_with_ltfu: Hash.new(0),
          assigned_patients: Hash.new(0),
          controlled_patients: Hash.new(0),
          controlled_patients_with_ltfu: Hash.new(0),
          controlled_patients_rate: Hash.new(0),
          controlled_patients_with_ltfu_rate: Hash.new(0),
          cumulative_registrations: Hash.new(0),
          cumulative_assigned_patients: Hash.new(0),
          earliest_registration_period: nil,
          ltfu_patients: Hash.new(0),
          ltfu_patients_rate: Hash.new(0),
          missed_visits_rate: {},
          missed_visits: {},
          period_info: {},
          registrations: Hash.new(0),
          uncontrolled_patients: Hash.new(0),
          uncontrolled_patients_rate: Hash.new(0)
        }.with_indifferent_access
    end

    attr_reader :region
    attr_reader :period_type
    attr_reader :current_period

    def []=(key, values)
      @data[key] = values
    end

    def [](key)
      @data[key]
    end

    def to_hash
      @data
    end

    delegate :dig, to: :@data

    # Return a new Result limited to just the report data range requested
    # We do this because we cache all the data, but clients may be expecting just the range of data that they
    # care to expose to the view or API consumers.
    def report_data_for(range)
      report_data = @data.each_with_object({}) { |(key, hsh_or_array), hsh|
        hsh[key] = if !hsh_or_array.is_a?(Hash)
          hsh_or_array
        else
          sliced_hsh = hsh_or_array.slice(*range.entries)
          sliced_hsh.default = hsh_or_array.default
          sliced_hsh
        end
      }.with_indifferent_access
      Result.new(region: region, period_type: period_type, data: report_data)
    end

    # Return all periods for the entire set of data for a Region - from the first registrations until
    # the most recent period
    def full_data_range
      if earliest_registration_period.nil?
        (current_period..current_period)
      else
        (earliest_registration_period..current_period)
      end
    end

    def fill_in_nil_registrations
      registrations.default = 0
      assigned_patients.default = 0
      full_data_range.each do |period|
        registrations[period] ||= 0
        assigned_patients[period] ||= 0
      end
    end

    def to_s
      "#{self.class} #{object_id} region=#{@region.name} period_type=#{period_type}"
    end

    def last_value(key)
      self[key].values.last
    end

    def last_key(key)
      self[key].keys.last
    end

    [:period_info, :earliest_registration_period,
      :registrations, :cumulative_registrations,
      :assigned_patients, :cumulative_assigned_patients,
      :ltfu_patients,
      :adjusted_registrations_with_ltfu, :adjusted_registrations,
      :missed_visits, :missed_visits_rate,
      :controlled_patients, :controlled_patients_with_ltfu,
      :controlled_patients_rate, :controlled_patients_with_ltfu_rate,
      :uncontrolled_patients, :uncontrolled_patients_rate,
      :visited_without_bp_taken, :visited_without_bp_taken_rate].each do |key|
      define_method(key) do
        self[key]
      end

      setter = "#{key}="
      define_method(setter) do |value|
        self[key] = value
      end

      define_method("#{key}_for") do |period|
        self[key][period]
      end

      define_method("#{key}_for!") do |period|
        self[key].fetch(period) { raise ArgumentError, "no data found for #{period} for #{key}" }
      end
    end

    # Adjusted registrations are the cumulative registrations (with exclusions) as of three months ago.
    # We use these for all the percentage calculations to exclude recent registrations.
    def count_adjusted_registrations_with_ltfu
      adjusted_registration_counts = full_data_range.each_with_object(Hash.new(0)) { |period, counts|
        adjusted_period = period.advance(months: -3)
        counts[period] = assigned_patients[adjusted_period]
      }

      self.adjusted_registrations_with_ltfu = running_totals(adjusted_registration_counts)
    end

    def count_adjusted_registrations
      self.adjusted_registrations = full_data_range.each_with_object(Hash.new(0)) do |period, running_totals|
        running_totals[period] = adjusted_registrations_with_ltfu[period] - ltfu_patients[period]
      end
    end

    def count_cumulative_assigned_patients
      self.cumulative_assigned_patients = running_totals(assigned_patients)
    end

    def count_cumulative_registrations
      self.cumulative_registrations = running_totals(registrations)
    end

    # "Missed visits" is the remaining registered patients when we subtract out the other three groups.
    def calculate_missed_visits(range)
      self.missed_visits = range.each_with_object(Hash.new(0)) { |(period, visit_count), hsh|
        registrations = adjusted_registrations_for(period)
        controlled = controlled_patients_for(period)
        uncontrolled = uncontrolled_patients_for(period)
        visited_without_bp_taken = visited_without_bp_taken_for(period)
        missed_visits = registrations - visited_without_bp_taken - controlled - uncontrolled
        hsh[period] = missed_visits.try(:floor) || 0
      }
    end

    # To determine the missed visits percentage, we sum the remaining percentages and subtract that from 100.
    # If we determined the percentage directly, we would have cases where the percentages do not add up to 100
    # due to rounding and losing precision.
    def calculate_missed_visits_percentages(range)
      self.missed_visits_rate = range.each_with_object(Hash.new(0)) do |period, hsh|
        remaining_percentages = controlled_patients_rate_for(period) + uncontrolled_patients_rate_for(period) + visited_without_bp_taken_rate_for(period)
        hsh[period] = 100 - remaining_percentages
      end
    end

    DATE_FORMAT = "%-d-%b-%Y"
    def calculate_period_info(range)
      self.period_info = range.each_with_object({}) do |period, hsh|
        hsh[period] = {
          name: period.to_s,
          start_date: period.start_date.to_s(:day_mon_year),
          ltfu_since_date: period.start_date.advance(months: -12).to_s(:day_mon_year),
          bp_control_start_date: period.bp_control_range_start_date,
          bp_control_end_date: period.bp_control_range_end_date,
          bp_control_registration_date: period.bp_control_registrations_until_date
        }
      end
    end

    def registrations_for_quarterly_percentage
      {
        controlled_patients: :assigned_patients,
        uncontrolled_patients: :assigned_patients,
        controlled_patients_with_ltfu: :assigned_patients,
        visited_without_bp_taken: :assigned_patients,
        ltfu_patients: :cumulative_registrations
      }
    end

    def registrations_for_monthly_percentage
      {
        controlled_patients: :adjusted_registrations,
        uncontrolled_patients: :adjusted_registrations,
        controlled_patients_with_ltfu: :adjusted_registrations_with_ltfu,
        visited_without_bp_taken: :adjusted_registrations,
        ltfu_patients: :cumulative_registrations
      }
    end

    def denominator_for_percentage_calculation(period, key)
      if quarterly_report?
        self[registrations_for_quarterly_percentage[key]][period.previous] || 0
      else
        self[registrations_for_monthly_percentage[key]][period]
      end
    end

    def calculate_percentages(key)
      key_for_percentage_data = "#{key}_rate"
      self[key_for_percentage_data] = self[key].each_with_object(Hash.new(0)) { |(period, value), hsh|
        hsh[period] = percentage(value, denominator_for_percentage_calculation(period, key))
      }
    end

    def quarterly_report?
      @quarterly_report
    end

    def percentage(numerator, denominator)
      return 0 if denominator == 0 || numerator == 0
      ((numerator.to_f / denominator) * 100).round(PERCENTAGE_PRECISION)
    end

    def running_totals(periodwise_counts)
      full_data_range.each_with_object(Hash.new(0)) { |period, running_totals|
        previous_total = running_totals[period.previous]
        current_count = periodwise_counts[period]
        total = previous_total + current_count
        running_totals[period] = total
      }
    end
  end
end
