module Reports
  class RegionAndPeriodFetcher
    attr_reader :repository

    def initialize(repository)
      @repository = repository
      @region = region
      @period = period
    end

    def respond_to_missing?(name, include_private = false)
      respository.respond_to?(name, include_private)
    end

    def method_missing(method, *args, &block)
      repository.send(method)[region][period]
    end

  end
end