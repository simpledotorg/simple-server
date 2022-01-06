# frozen_string_literal: true

module Reports
  class RegionEntry
    def initialize(region, calculation, **options)
      @region = region
      @calculation = calculation
      @options = options.to_a
    end

    def cache_key
      [@region.cache_key, @calculation, @options].join("/")
    end

    alias_method :to_s, :cache_key

    attr_reader :region
    delegate :slug, to: :region
  end
end
