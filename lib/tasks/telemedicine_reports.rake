# frozen_string_literal: true

require "tasks/scripts/telemedicine_reports"

namespace :reports do
  desc "Generates the telemedicine report, takes the mixpanel report as input"
  task :telemedicine, [:mixpanel_report, :period_start, :period_end] => :environment do |_t, args|
    # bundle exec telemedicine_reports[<path_to_mixpanel_report>,'2020-06-07','2020-06-13']
    # This task generates a telemedicine report for the given period
    # It takes a mixpanel report (https://mixpanel.com/report/2029051/view/133579/insights#report/9098268/weekly-data-for-taps-on-contact-doctor),
    # and start and end dates for the period as input and generates a `telemedicine_report.csv` file containing the relevant information.

    # The mixpanel report needs to be generated using the same period start and end dates to get an accurate report.

    mixpanel_csv = args[:mixpanel_report]
    period_start = Date.parse(args[:period_start]).beginning_of_day
    period_end = Date.parse(args[:period_end]).end_of_day

    abort "Requires a valid file path." unless mixpanel_csv.present?
    abort "Requires a valid file path." unless File.file?(mixpanel_csv)
    abort "Requires valid start and end dates." unless period_start.is_a?(ActiveSupport::TimeWithZone) &&
      period_end.is_a?(ActiveSupport::TimeWithZone)

    mixpanel_data = TelemedicineReports.parse_mixpanel(mixpanel_csv)
    TelemedicineReports.generate_report(mixpanel_data, period_start, period_end)
  end
end
