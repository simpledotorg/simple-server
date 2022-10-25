module Reports
  class RegionCacheWarmer
    prepend SentryHandler
    BATCH_SIZE = 250

    def self.call(*args)
      new(*args).call
    end

    attr_reader :batch_size

    def initialize(batch_size: BATCH_SIZE)
      @batch_size = batch_size
    end

    def call
      Rails.logger.info "Starting queuing cache warming jobs"

      Region::REGION_TYPES.excluding("root").each do |region_type|
        Region.where(region_type: region_type).in_batches(of: batch_size).each_with_index do |_, batch_index|
          queue_job(region_type, batch_index)
        end
      end

      Rails.logger.info "Finished queueing cache warming jobs"
    end

    private

    def queue_job(region_type, batch_index)
      limit = batch_size
      offset =  batch_index * batch_size
      RegionCacheWarmerJob.perform_async(region_type, limit, offset)
    end
  end
end
