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
          adjusted_patient_counts: Hash.new(0),
          adjusted_patient_counts_with_ltfu: Hash.new(0),
          assigned_patients: Hash.new(0),
          controlled_patients: Hash.new(0),
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
          region: region,
          registrations: Hash.new(0),
          uncontrolled_patients: Hash.new(0),
          uncontrolled_patients_rate: Hash.new(0),
          uncontrolled_patients_with_ltfu_rate: Hash.new(0)
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
      :ltfu_patients_rate,
      :adjusted_patient_counts_with_ltfu, :adjusted_patient_counts,
      :controlled_patients,
      :controlled_patients_rate,
      :controlled_patients_with_ltfu_rate,
      :uncontrolled_patients,
      :uncontrolled_patients_rate,
      :uncontrolled_patients_with_ltfu_rate,
      :visited_without_bp_taken,
      :visited_without_bp_taken_rate,
      :visited_without_bp_taken_with_ltfu_rate,
      :missed_visits, :missed_visits_with_ltfu,
      :missed_visits_rate,
      :missed_visits_with_ltfu_rate].each do |key|
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

    DATE_FORMAT = "%-d-%b-%Y"
    QUARTELY_DENOMINATORS = {
      controlled_patients: :assigned_patients,
      uncontrolled_patients: :assigned_patients,
      visited_without_bp_taken: :assigned_patients,
      ltfu_patients: :cumulative_registrations
    }
    MONTHLY_DENOMINATORS = {
      with_ltfu: {
        controlled_patients: :adjusted_patient_counts_with_ltfu,
        uncontrolled_patients: :adjusted_patient_counts_with_ltfu,
        visited_without_bp_taken: :adjusted_patient_counts_with_ltfu,
        ltfu_patients: :cumulative_registrations
      },
      excluding_lftu: {
        controlled_patients: :adjusted_patient_counts,
        uncontrolled_patients: :adjusted_patient_counts,
        visited_without_bp_taken: :adjusted_patient_counts,
        ltfu_patients: :cumulative_registrations
      }
    }

    def quarterly_denominator(numerator)
      self[QUARTELY_DENOMINATORS[numerator]]
    end

    def monthly_denominator(numerator, with_ltfu:)
      ltfu_key = if with_ltfu
        :with_ltfu
      else
        :excluding_lftu
      end

      self[MONTHLY_DENOMINATORS[ltfu_key][numerator]]
    end

    def denominator_for_percentage_calculation(period, key, with_ltfu:)
      if quarterly_report?
        quarterly_denominator(key)[period.previous] || 0
      else
        monthly_denominator(key, with_ltfu: with_ltfu)[period]
      end
    end

    def calculate_percentages(key, with_ltfu: false)
      key_for_percentage_data = if with_ltfu
        "#{key}_with_ltfu_rate"
      else
        "#{key}_rate"
      end

      self[key_for_percentage_data] = self[key].each_with_object(Hash.new(0)) { |(period, value), hsh|
        hsh[period] = percentage(value, denominator_for_percentage_calculation(period, key, with_ltfu: with_ltfu))
      }
    end

    def percentage(numerator, denominator)
      return 0 if denominator == 0 || numerator == 0
      ((numerator.to_f / denominator) * 100).round(PERCENTAGE_PRECISION)
    end

    def quarterly_report?
      @quarterly_report
    end
  end
end
