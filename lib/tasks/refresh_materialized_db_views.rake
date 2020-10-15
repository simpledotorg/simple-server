# frozen_string_literal: true

desc "Refresh materialized views for dashboards"
task refresh_materialized_views: :environment do
  RefreshMaterializedViews.call
end
