class BloodPressureExportService
  require "csv"
  include ActionView::Helpers::NumberHelper
  include DashboardHelper

  attr_reader :start_period, :end_period, :facilities, :data_for_facility, :stats_by_size, :display_sizes

  FACILITY_SIZES = %w[large medium small community]
  DATA_TYPES = [:controlled_patients_rate, :uncontrolled_patients_rate, :missed_visits_rate]

  def initialize(start_period:, end_period:, facilities:)
    @start_period = start_period
    @end_period = end_period
    @facilities = facilities

    presenter = Reports::RepositoryPresenter.create(facilities, period: @end_period, months: 6)
    @data_for_facility = facilities.each_with_object({}) do |facility, result|
      result[facility.name] = presenter.my_facilities_hash(facility.region)
    end
    found_sizes = @facilities.pluck(:facility_size).uniq
    @sizes = FACILITY_SIZES.select { |size| size.in?(found_sizes) }
    @stats_by_size = FacilityStatsService.call(facilities: @data_for_facility, period: @end_period)
  end

  def call
    aggregate_data
  end

  def as_csv
    CSV.generate { |csv|
      headers = set_csv_headers
      headers.each do |header_row|
        csv << header_row
      end
      data = aggregate_data
      data.keys.each_with_index do |size, i|
        aggregate = data[size]["aggregate"]
        row = []
        row << aggregate["Facilities"]
        row << aggregate["Total assigned"]
        row << aggregate["Total registered"]
        aggregate[:controlled_patients_rate].each_pair do |key, value|
          row << value
        end
        aggregate[:uncontrolled_patients_rate].each_pair do |key, value|
          row << value
        end
        aggregate[:missed_visits_rate].each_pair do |key, value|
          row << value
        end

        csv << row
        facilities = data[size]["facilities"]
        facilities.sort_by { |a| a["Facilities"] }.each do |facility|
          facility_row = []
          facility_row << facility["Facilities"]
          facility_row << facility["Total assigned"]
          facility_row << facility["Total registered"]
          DATA_TYPES.each do |rate_type|
            facility[rate_type].each_pair do |key, value|
              facility_row << value
            end
          end
          csv << facility_row
        end
        csv << [] if i != @sizes.length - 1
      end
    }
  end

  private

  def aggregate_data
    @aggregate_data ||= begin
      formatted = {}
      @sizes.each do |size|
        if !formatted[size]
          formatted[size] = {}
          formatted[size]["aggregate"] = format_aggregate_facility_stats(size)
          formatted[size]["facilities"] = format_facilities_of_size(size)
        end
      end
      formatted
    end
  end

  def set_csv_headers
    headers = []
    spacing = (@start_period..@end_period).map { "" }
    first_row_headers = ["Facilities", "Total assigned", "Total registered", "BP controlled", *spacing, "BP not controlled", *spacing, "Missed Visits", *spacing]
    second_row_headers = ["", "", ""]
    3.times do
      second_row_headers << "6 month change"
      (@start_period..@end_period).each { |period| second_row_headers << period }
    end
    headers << first_row_headers << second_row_headers
    headers
  end

  def format_aggregate_facility_stats(size)
    aggregate_row = {}
    period_data = @stats_by_size[size][:periods]

    aggregate_row["Facilities"] = "All #{Facility.localized_facility_size(size, pluralize: true)}"

    aggregate_assigned = number_or_zero_with_delimiter(period_data[end_period][:cumulative_assigned_patients])
    aggregate_row["Total assigned"] = aggregate_assigned

    aggregate_registered = number_or_zero_with_delimiter(period_data[end_period][:cumulative_registrations])
    aggregate_row["Total registered"] = aggregate_registered

    DATA_TYPES.each do |rate_type|
      aggregate_row[rate_type] = {} unless aggregate_row.key?(rate_type)
      six_month_change = stats_by_size[size][:periods][end_period][rate_type] - stats_by_size[size][:periods][start_period][rate_type]
      aggregate_row[rate_type]["6 month change"] = number_to_percentage(six_month_change || 0, precision: 0)
      (start_period..end_period).each do |period|
        aggregate_row[rate_type][period.to_s] = number_to_percentage(stats_by_size[size][:periods][period][rate_type] || 0, precision: 0)
      end
    end
    aggregate_row
  end

  def format_facilities_of_size(size)
    row = []
    @data_for_facility.each do |_, facility_data|
      facility_size = facility_data[:facility_size]
      next if facility_size != size
      row << format_individual_facility_stats(facility_data)
    end
    row
  end

  def format_individual_facility_stats(facility_data)
    row = {}
    facility = facility_data[:facility]
    row["Facilities"] = facility.name

    total_assigned = number_or_zero_with_delimiter(facility_data[:cumulative_assigned_patients].values.last)
    row["Total assigned"] = total_assigned

    total_registered = number_or_zero_with_delimiter(facility_data[:cumulative_registrations].values.last)
    row["Total registered"] = total_registered

    DATA_TYPES.each do |rate_type|
      row[rate_type] = {} unless row.key?(rate_type)
      six_month_rate_change = six_month_rate_change(facility, rate_type)
      row[rate_type]["6 month change"] = number_to_percentage(six_month_rate_change || 0, precision: 0)
      (start_period..end_period).each do |period|
        data_type_rate = facility_data[rate_type][period]
        row[rate_type][period.to_s] = number_to_percentage(data_type_rate || 0, precision: 0)
      end
    end
    row
  end

  # is the || 0 necessary?
  def facility_size_six_month_rate_change(facility_size_data, rate_name)
    facility_size_data[end_period][rate_name] - facility_size_data[start_period][rate_name] || 0
  end

  def six_month_rate_change(facility, rate_name)
    data = data_for_facility[facility.name].fetch(rate_name) { |key| raise(ArgumentError, "missing data for #{facility.name} for rate #{rate_name} ") }
    data[end_period] - data[start_period] || 0
  end
end
