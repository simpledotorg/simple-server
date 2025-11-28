module DrRai
  class DataService
    class << self
      def populate klazz, timeline: nil
        raise "Can only populate models" unless klazz < ApplicationRecord
        if timeline.present?
          raise "timeline must be Date range" unless timeline.is_a?(Range)
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
      @query = if inserting?
        @query_factory.inserter
      else
        @query_factory.updater
      end

      ApplicationRecord.connection.exec_query(@query)
    end

    private

    def inserting?
      @klazz.insert_window(@timeline).count == 0
    end
  end
end
