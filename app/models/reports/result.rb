module Reports
  class Result
    PERCENTAGE_PRECISION = 0

    def initialize(range)
      @range = range
      @quarterly_report = @range.begin.quarter?
      @data = {
        adjusted_registrations: Hash.new(0),
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

    def last_value(key)
      self[key].values.last
    end

    [:adjusted_registrations, :controlled_patients, :controlled_patients_rate, :cumulative_registrations, :missed_visits, :missed_visits_rate,
      :registrations, :uncontrolled_patients, :uncontrolled_patients_rate, :visited_without_bp_taken, :visited_without_bp_taken_rate].each do |key|
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
    end

    # Adjusted registrations are the registrations as of three months ago - we use these for all the percentage
    # calculations to exclude recent registrations.
    def count_adjusted_registrations
      self.adjusted_registrations = range.each_with_object(Hash.new(0)) do |period, hsh|
        hsh[period] = cumulative_registrations_for(period.advance(months: -3))
      end
    end

    # "Missed visits" is the remaining registerd patients when we subtract out the other three groups.
    def count_missed_visits
      self[:missed_visits] = range.each_with_object({}) { |(period, visit_count), hsh|
        registrations = adjusted_registrations_for(period)
        controlled = controlled_patients_for(period)
        uncontrolled = uncontrolled_patients_for(period)
        visited_without_bp_taken = visited_without_bp_taken_for(period)
        hsh[period] = registrations - visited_without_bp_taken - controlled - uncontrolled
      }
    end

    def registrations_for_percentage_calculation(period)
      if quarterly_report?
        self[:registrations][period.previous] || 0
      else
        adjusted_registrations_for(period)
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
