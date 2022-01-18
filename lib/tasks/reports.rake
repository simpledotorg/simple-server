# frozen_string_literal: true

require "tasks/scripts/telemedicine_reports_v2"

namespace :reports do
  desc "Generates the telemedicine report"
  task telemedicine: :environment do
    period_start = Date.today.prev_occurring(:monday).beginning_of_day
    period_end = period_start.next_occurring(:sunday).end_of_day

    report = TelemedicineReportsV2.new(period_start, period_end)
    report.generate
  end
end
