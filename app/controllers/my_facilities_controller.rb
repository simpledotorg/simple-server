# frozen_string_literal: true

class MyFacilitiesController < AdminController
  include Pagination
  include MyFacilitiesFiltering
  include CohortPeriodSelection
  include PeriodSelection
  ###
  # include ActionView::Helpers::NumberHelper
  # include DashboardHelper
  # require 'csv'
  # include BloodPressureExportService

  PERIODS_TO_DISPLAY = {quarter: 3, month: 3, day: 14}.freeze

  around_action :set_reporting_time_zone
  before_action :set_period, except: [:index]
  before_action :authorize_my_facilities
  before_action :set_selected_cohort_period, only: [:blood_pressure_control]
  before_action :set_selected_period, only: [:registrations, :missed_visits]
  before_action :set_last_updated_at

  def index
    @facilities = current_admin.accessible_facilities(:view_reports)
    users = current_admin.accessible_users(:manage)

    @users_requesting_approval = paginate(users
                                            .requested_sync_approval
                                            .order(updated_at: :desc))

    overview_query = OverviewQuery.new(facilities: @facilities)
    @inactive_facilities = overview_query.inactive_facilities

    @facility_counts_by_size = {total: @facilities.group(:facility_size).count,
                                inactive: @inactive_facilities.group(:facility_size).count}

    @inactive_facilities_bp_counts =
      {last_week: overview_query.total_bps_in_last_n_days(n: 7),
       last_month: overview_query.total_bps_in_last_n_days(n: 30)}
  end

  def bp_controlled
    process_facility_stats(:controlled_patients)
  end

  def bp_not_controlled
    process_facility_stats(:uncontrolled_patients)
  end

  def missed_visits
    process_facility_stats(:missed_visits)
  end
############################### -- URL to localhost:3000/my_facilities/csv_maker, I added a line in routes.rb for this method
  def csv_maker
    rate_name = params[:type]

    # send_data generate_csv_with_formatted_stats(rate_name),  type: "text/csv", filename: "BP #{params[:type].split("_").map(&:titleize).join(" ")} #{@selected_facility_group.name}.csv"
    send_data BloodPressureExportService.new(start_period: @start_period, end_period: @period, data_type:rate_name, facilities: filter_facilities).call,  type: "text/csv", filename: "BP #{params[:type].split("_").map(&:titleize).join(" ")} #{@selected_facility_group.name}.csv"
  end
##################################
  private

  def set_last_updated_at
    last_updated_at = RefreshReportingViews.last_updated_at
    @last_updated_at =
      if last_updated_at.nil?
        "unknown"
      else
        last_updated_at.in_time_zone(Rails.application.config.country[:time_zone]).strftime("%d-%^b-%Y %I:%M%p")
      end
  end

  def authorize_my_facilities
    authorize { current_admin.accessible_facilities(:view_reports).any? }
  end

  def set_period
    @period = Period.month(Date.current.last_month.beginning_of_month)
    @start_period = @period.advance(months: -5)
  end

  def report_params
    params.permit(:id, :bust_cache, :report_scope, {period: [:type, :value]})
  end

  def process_facility_stats(type)
    facilities = filter_facilities
    @data_for_facility = {}

    facilities.each do |facility|
      @data_for_facility[facility.name] = Reports::RegionService.new(
        region: facility.region, period: @period, months: 6
      ).call
    end
    sizes = @data_for_facility.map { |_, facility| facility.region.source.facility_size }.uniq
    @display_sizes = @facility_sizes.select { |size| sizes.include? size }
    @stats_by_size = FacilityStatsService.call(facilities: @data_for_facility, period: @period, rate_numerator: type)
  end


  #DATA WE WANT IS:
  #facility_name
  # cumulative_assigned_patients 
  # cumulative_registrations
  # 6 month change
  # data_type #controlled_patients / uncontrolled_patients / missed_visits
  # adjusted_patient_counts
  # data_rate #controlled_patients_rate / uncontrolled_patients_rate / missed_visits_rate

  # def generate_csv_with_formatted_stats(type)
  #   CSV.generate(){|csv|
  #     data = format_processed_stats_to_csv_rows(type)
  #     headers = set_csv_headers
  #     ###reserve line to add method to format headers to titlize and un-snakecase them
  #     csv << headers
  #     data.keys.each_with_index do |size, i|
  #       csv << data[size]["aggregate"].values_at(*headers)
  #       data[size]["facilities"].each do |row_object|
  #         csv << row_object.values_at(*headers)
  #       end
  #       csv << [] if i != @display_sizes.length-1
  #     end
  #   }
  # end

  # def format_processed_stats_to_csv_rows(type)
  #   process_facility_stats(type)
  #   formatted = {}
  #   @display_sizes.each do |size|
  #     if !formatted[size]
  #       formatted[size] = {}
  #       formatted[size]["aggregate"] = format_aggregate_facility_stats(type, size)
  #       formatted[size]["facilities"] = format_subsequent_stats(type, size)
  #     end

  #   end
  #   formatted
  # end

  # def set_csv_headers
  #   headers = ["facilities", "total_assigned", "total_registered","six_month_change"]
  #   (@start_period..@period).each {|period| headers << period << "#{period}-ratio" }
  #   headers
  # end

  # def format_aggregate_facility_stats(type, size)
  #   aggregate_row = {}
  #   facility_size_six_month_rate_change = facility_size_six_month_rate_change(@stats_by_size[size][:periods], "#{type}_rate")
  #   aggregate_row["facilities"] = "All #{Facility.localized_facility_size(size)}s"
  #   aggregate_row["total_assigned"] = number_or_zero_with_delimiter(@stats_by_size[size][:periods][@period][:cumulative_assigned_patients])
  #   aggregate_row["total_registered"] = number_or_zero_with_delimiter(@stats_by_size[size][:periods][@period][:cumulative_registrations])
  #   aggregate_row["six_month_change"] =  number_to_percentage_with_symbol(facility_size_six_month_rate_change, precision: 0)
  #   @stats_by_size[size][:periods].each_pair do |period, data| 
  #     type_rate = data["#{type}_rate"]
  #     aggregate_row[period] = number_to_percentage(type_rate || 0, precision: 0)
  #     aggregate_row["#{period}-ratio"] = "#{data[type]} / #{data["adjusted_patient_counts"]}"
  #   end
  #   aggregate_row
  # end

  # def format_subsequent_stats(type, size)
  #   row = []
  #   @data_for_facility.each do |_, facility_data| #Hash iterator for subsequent rows
  #     facility_row_obj = {}
  #     facility = facility_data.region.source
  #     next if facility.facility_size != size
  #     six_month_rate_change = six_month_rate_change(facility, "#{type}_rate")
  #     facility_row_obj["facilities"] = facility.name # Facility name
  #     facility_row_obj["total_assigned"] = number_or_zero_with_delimiter(facility_data["cumulative_assigned_patients"].values.last) # Assigned
  #     facility_row_obj["total_registered"] = number_or_zero_with_delimiter(facility_data["cumulative_registrations"].values.last) # Registered
  #     facility_row_obj["six_month_change"] = number_to_percentage_with_symbol(six_month_rate_change, precision: 0) # 6 month change
  #     (@start_period..@period).each do |period|
  #       type_rate = facility_data["#{type}_rate"][period] #redeclaring this variable for the inner loop we are using
  #       facility_row_obj[period] = number_to_percentage(type_rate || 0, precision: 0) #Monthly rate
  #       facility_row_obj["#{period}-ratio"] = "#{facility_data[type][period]} / #{facility_data["adjusted_patient_counts"][period]}" #Monthly ratio
  #     end
  #     row << facility_row_obj
  #   end
  #   row
  # end



end