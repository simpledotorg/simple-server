# frozen_string_literal: true

namespace :db do
  desc "Refresh materialized views for dashboards"
  task refresh_materialized_views: :environment do
    RefreshMaterializedViews.call
  end
end
