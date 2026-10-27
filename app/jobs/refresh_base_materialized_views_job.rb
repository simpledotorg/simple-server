class RefreshBaseMaterializedViewsJob
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform
    Rails.logger.info "Starting refresh of base materialized views after region move"

    # Refresh only the base views that don't involve partitioned tables
    # These provide foundation data for partitioned tables
    base_views = [
      "Reports::Month",
      "Reports::Facility",
      "Reports::PatientBloodPressure",
      "Reports::PatientBloodSugar",
      "Reports::OverdueCalls",
      "Reports::PatientVisit",
      "Reports::PatientFollowUp"
    ]

    RefreshReportingViews.call(views: base_views)
    Rails.logger.info "Successfully refreshed base materialized views"
  rescue => e
    Rails.logger.error "Failed to refresh base materialized views: #{e.message}"
    raise e
  end
end
