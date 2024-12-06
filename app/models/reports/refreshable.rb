module Reports
  module Refreshable
    # Refresh a materialized view.
    #
    # By default this will be done within a transaction, unless the `transaction` arg is set to false
    def refresh(transaction: true)
      return refresh_view unless transaction
      ActiveRecord::Base.transaction do
        set_work_mem if Flipper.enabled?(:optimize_work_mem)
        refresh_view
      end
    end

    private

    def set_work_mem
      work_mem = ENV.fetch("REFRESH_WORK_MEM", nil)
      return Rails.logger.warn("REFRESH_WORK_MEM is not set, falling back to default value") if work_mem.nil?

      ActiveRecord::Base.connection.execute("SET LOCAL work_mem TO '#{work_mem}'")
    end

    def refresh_view
      ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{Period::REPORTING_TIME_ZONE}'")
      Scenic.database.refresh_materialized_view(table_name, concurrently: refresh_concurrently?, cascade: false)
    end

    def refresh_concurrently?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch("REFRESH_MATVIEWS_CONCURRENTLY", true))
    end
  end
end
