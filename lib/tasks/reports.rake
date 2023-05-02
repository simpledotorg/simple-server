# frozen_string_literal: true

require "tasks/scripts/telemedicine_reports_v2"

namespace :reports do
  desc "Generates the telemedicine report"
  task telemedicine: :environment do
    period_start = (Date.today - 1.month).beginning_of_month
    period_end = period_start.end_of_month

    report = TelemedicineReportsV2.new(period_start, period_end)
    report.generate
  end
end
