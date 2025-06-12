class RefreshReportingPartitionedTableJob
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(reporting_month, table_name)
    Rails.logger.info "Starting refresh for '#{table_name}' for month '#{reporting_month}' at #{Time.now.utc}"
    ActiveRecord::Base.connection.exec_query(
      "CALL simple_reporting.add_shard_to_table('#{reporting_month}', '#{table_name}')"
    )
  end
end
