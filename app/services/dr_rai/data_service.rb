module DrRai
  class DataService
    class << self
      def populate klazz, timeline: nil
        raise "Can only populate models" unless klazz < ApplicationRecord
        if timeline.present?
          raise "timeline must be Date range" unless timelines.is_a?(Range)
        end
        new(klazz, timeline).populate!
      end
    end

    def initialize klazz, timeline
      @klazz = klazz
      @timeline = timeline
      @timeline = 1.year.ago.to_date..Date.today if @timeline.nil?
      @query_factory = QueryFactory.for(klazz, from: @timeline.begin, to: @timeline.end)
    end

    def populate!
      if inserting?
        @query = @query_factory.inserter
      else
        @query = @query_factory.updater
      end

      ApplicationRecord.connection.exec_query(@query)
    end

    private

    def inserting?
      @klazz.where(month_date: @timeline).count == 0
    end
  end
end
