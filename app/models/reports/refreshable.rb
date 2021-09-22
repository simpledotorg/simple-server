module Reports
  module Refreshable
    # Refresh a materialized view.
    #
    # By default this will be done within a transaction, unless the `transaction` arg is set to false
    def refresh(transaction: true)
      return refresh_view unless transaction
      ActiveRecord::Base.transaction do
        refresh_view
      end
    end

    private

    def refresh_view
      ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{Period::REPORTING_TIME_ZONE}'")
      logger.info "refreshing #{table_name} concurrently: #{refresh_concurrently?}"
      Scenic.database.refresh_materialized_view(table_name, concurrently: refresh_concurrently?, cascade: false)
    end

    def refresh_concurrently?
      if ENV.key?("REFRESH_MATVIEWS_CONCURRENTLY")
        ActiveModel::Type::Boolean.new.cast(ENV["REFRESH_MATVIEWS_CONCURRENTLY"])
      else
        true
      end
    end
  end
end
