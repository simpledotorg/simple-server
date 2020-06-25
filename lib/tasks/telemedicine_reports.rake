# frozen_string_literal: true

require "tasks/scripts/telemedicine_reports"

namespace :reports do
  desc "Generates the telemedicine report, takes the mixpanel report as input"
  task :telemedicine, [:mixpanel_report, :p1_start, :p1_end, :p2_start, :p2_end] => :environment do |_t, args|
    # bundle exec telemedicine_reports[<path_to_mixpanel_report>,'2020-06-07','2020-06-13','2020-06-14','2020-06-21']
    # This task generates a telemedicine report that compares telemedicine usage between two periods (eg: week,month etc)
    # It takes a mixpanel report (https://mixpanel.com/report/2029051/insights#report/9098268/week-on-week-comparision-for-taps-on-contact-doctor),
    # and start and end dates for the period as input and generates a `telemedicine_report.csv` file containing the relevant information.

    # The mixpanel report needs to be generated using the same period start and end dates to get an accurate report.

    mixpanel_csv = args[:mixpanel_report]
    p1_start = Date.parse(args[:p1_start]).beginning_of_day
    p1_end = Date.parse(args[:p1_end]).end_of_day
    p2_start = Date.parse(args[:p2_start]).beginning_of_day
    p2_end = Date.parse(args[:p2_end]).end_of_day

    abort "Requires a valid file path." unless mixpanel_csv.present?
    abort "Requires a valid file path." unless File.file?(mixpanel_csv)

    mixpanel_data = TelemedicineReports.parse_mixpanel(mixpanel_csv)
    TelemedicineReports.generate_report(mixpanel_data, p1_start, p1_end, p2_start, p2_end)
  end
end
