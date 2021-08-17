module Reports
  class Result
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

    def to_s
      "#{self.class} #{object_id} region=#{@region.name} period_type=#{period_type}"
    end

    [:period_info, :earliest_registration_period,
      :registrations, :cumulative_registrations,
      :assigned_patients, :cumulative_assigned_patients,
      :ltfu_patients,
      :ltfu_patients_rate,
      :adjusted_patient_counts_with_ltfu,
      :adjusted_patient_counts,
      :controlled_patients,
      :controlled_patients_rate,
      :controlled_patients_with_ltfu_rate,
      :uncontrolled_patients,
      :uncontrolled_patients_rate,
      :uncontrolled_patients_with_ltfu_rate,
      :visited_without_bp_taken,
      :visited_without_bp_taken_rates,
      :visited_without_bp_taken_with_ltfu_rates,
      :missed_visits,
      :missed_visits_with_ltfu,
      :missed_visits_rate,
      :missed_visits_with_ltfu_rate].each do |key|
      define_method(key) do
        self[key]
      end

      setter = "#{key}="
      define_method(setter) do |value|
        self[key] = value
      end
    end

    def quarterly_report?
      @quarterly_report
    end
  end
end
