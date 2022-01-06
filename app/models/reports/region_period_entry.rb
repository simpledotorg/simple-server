# frozen_string_literal: true

module Reports
  class RegionPeriodEntry
    attr_reader :namespace, :region, :period, :calculation

    def initialize(namespace, region, period, calculation, **options)
      @namespace = namespace
      @region = region
      @period = period
      @calculation = calculation
      @options = options.to_a
    end

    def cache_key
      [namespace, region.cache_key, period.cache_key, calculation, @options].join("/")
    end

    delegate :adjusted_period, to: :period
    delegate :slug, to: :region
    alias_method :to_s, :cache_key
  end
end
