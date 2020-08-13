module Reports
  class Result
    def initialize(range)
      @range = range
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

  end
end