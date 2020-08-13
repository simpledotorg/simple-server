module Reports
  class Result
    PERCENTAGE_PRECISION = 0

    def initialize(range)
      @range = range
      @quarterly_report = @range.begin.quarter?
      @data = {
        controlled_patients_rate: Hash.new(0),
        controlled_patients: Hash.new(0),
        cumulative_registrations: Hash.new(0),
        missed_visits_rate: {},
        missed_visits: {},
        quarterly_registrations: [],
        registrations: Hash.new(0),
        top_region_benchmarks: {},
        uncontrolled_patients: Hash.new(0),
        uncontrolled_patients_rate: Hash.new(0)
      }.with_indifferent_access
    end

    attr_reader :range

    def []=(key, values)
      @data[key] = values
    end

    def [](key)
      @data[key]
    end

    def to_hash
      @data
    end

    def merge!(other)
      @data.merge! other
    end

    [:cumulative_registrations, :registrations, :uncontrolled_patients, :controlled_patients, :visited_without_bp_taken].each do |key|
      define_method(key) do |period|
        self[key][period]
      end
    end

    # "Missed visits" is the remaining registerd patients when we subtract out the other three groups.
    def count_missed_visits
      self[:missed_visits] = range.each_with_object({}) do |(period, visit_count), hsh|
        registrations = cumulative_registrations(period)
        controlled = controlled_patients(period)
        uncontrolled = uncontrolled_patients(period)
        visited_without_bp_taken = visited_without_bp_taken(period)
        hsh[period] = registrations - visited_without_bp_taken - controlled - uncontrolled
      end
    end

    def registrations_for_percentage_calculation(period)
      if quarterly_report?
        self[:registrations][period.previous] || 0
      else
        self[:cumulative_registrations][period]
      end
    end

    def calculate_percentages(key)
      key_for_percentage_data = "#{key}_rate"
      self[key_for_percentage_data] = self[key].each_with_object(Hash.new(0)) { |(period, value), hsh|
        hsh[period] = percentage(value, registrations_for_percentage_calculation(period))
      }
    end

    def quarterly_report?
      @quarterly_report
    end

    def percentage(numerator, denominator)
      return 0 if denominator == 0 || numerator == 0
      ((numerator.to_f / denominator) * 100).round(PERCENTAGE_PRECISION)
    end
  end
end
