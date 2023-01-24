require "tasks/scripts/pre_fill_monthly_screening_reports"

namespace :questionnaires do
  desc "Pre-fill monthly screening reports responses with content"
  task pre_fill_monthly_screening_reports: :environment do
    PreFillMonthlyScreeningReports.call
  end
end
