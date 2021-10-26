class BloodPressureExportService
  require "csv"
  include ActionView::Helpers::NumberHelper
  include DashboardHelper

  attr_reader :start_period, :end_period, :facilities, :data_type, :data_for_facility, :stats_by_size, :display_sizes, :rate_key

  FACILITY_SIZES = %w[large medium small community]

  def initialize(data_type:, start_period:, end_period:, facilities:)
    @data_type = data_type
    @rate_key = "#{@data_type}_rate".to_sym
    @start_period = start_period
    @end_period = end_period
    @facilities = facilities

    presenter = Reports::RepositoryPresenter.create(facilities, period: @end_period, months: 6, reporting_schema_v2: RequestStore.store[:reporting_schema_v2])
    @data_for_facility = facilities.each_with_object({}) do |facility, result|
      result[facility.name] = presenter.my_facilities_hash(facility.region)
    end
    found_sizes = @facilities.pluck(:facility_size).uniq
    @sizes = FACILITY_SIZES.select { |size| size.in?(found_sizes) }
    @stats_by_size = FacilityStatsService.call(facilities: @data_for_facility, period: @end_period, rate_numerator: data_type)
  end

  def call
    aggregate_data
  end

  def as_csv
    CSV.generate { |csv|
      headers = set_csv_headers
      # ##reserve line to add method to format headers to titlize and un-snakecase them
      csv << headers
      aggregate_data.keys.each_with_index do |size, i|
        csv << aggregate_data[size]["aggregate"].values_at(*headers)
        aggregate_data[size]["facilities"].each do |row_object|
          csv << row_object.values_at(*headers)
        end
        csv << [] if i != @sizes.length - 1
      end
    }
  end

  private

  # def data_map
  #   [
  #     {
  #       "Facilities" => {
  #         "aggregate" => lambda { |size| "All #{Facility.localized_facility_size(size, pluralize: true)}" },
  #         "facility" => lambda { |facility| facility_data.region.source }
  #       }
  #     },
  #     {
  #     }
  #   ]
  # end

  # row = {}
  # data_map.each do |hsh|
  #   hsh.each_pair do |k,v|
  #     row[k] = v["aggregate"].call(size)
  #   end
  # end

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
    headers = ["Facilities", "Total assigned", "Total registered", "Six month change"]
    (@start_period..@end_period).each {|period| headers << period} # << "#{period}-ratio" }
    headers
  end

  def format_aggregate_facility_stats(size)
    aggregate_row = {}
    period_data = @stats_by_size[size][:periods]
    facility_size_six_month_rate_change = facility_size_six_month_rate_change(period_data, rate_key)
    aggregate_row["Facilities"] = "All #{Facility.localized_facility_size(size, pluralize: true)}"
    aggregate_row["Total assigned"] = number_or_zero_with_delimiter(period_data[@end_period][:cumulative_assigned_patients])
    aggregate_row["Total registered"] = number_or_zero_with_delimiter(period_data[@end_period][:cumulative_registrations])
    aggregate_row["Six month change"] = number_to_percentage_with_symbol(facility_size_six_month_rate_change, precision: 0)
    period_data.each_pair do |period, data|
      data_type_rate = data[rate_key]
      aggregate_row[period] = number_to_percentage(data_type_rate || 0, precision: 0)
      # aggregate_row["#{period}-ratio"] = "#{data[@data_type]} / #{data["adjusted_patient_counts"]}"
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
    facility_row_obj = {}
    facility = facility_data[:facility]
    six_month_rate_change = six_month_rate_change(facility, rate_key)
    facility_row_obj["Facilities"] = facility.name
    facility_row_obj["Total assigned"] = number_or_zero_with_delimiter(facility_data[:cumulative_assigned_patients].values.last)
    facility_row_obj["Total registered"] = number_or_zero_with_delimiter(facility_data[:cumulative_registrations].values.last)
    facility_row_obj["Six month change"] = number_to_percentage_with_symbol(six_month_rate_change, precision: 0)
    (@start_period..@end_period).each do |period|
      data_type_rate = facility_data[rate_key][period]
      facility_row_obj[period] = number_to_percentage(data_type_rate || 0, precision: 0)
      # facility_row_obj["#{period}-ratio"] = "#{facility_data[@data_type][period]} / #{facility_data["adjusted_patient_counts"][period]}"
    end
    facility_row_obj
  end

  # is the || 0 necessary?
  def facility_size_six_month_rate_change(facility_size_data, rate_name)
    facility_size_data[end_period][rate_name] - facility_size_data[start_period][rate_name] || 0
  end

  def six_month_rate_change(facility, rate_name)
    data = data_for_facility[facility.name].fetch(rate_name) { |key| raise(ArgumentError, "missing data for #{facility.name} for rate #{rate_name} ")}
    data[end_period] - data[start_period] || 0
  end
end

# filter_facilities returns this array of facilities depending on current admin user
# [#<Facility:0x00007f9801331120
#   id: "0fd2807e-06ee-470a-baad-287d0bd72904",
#   name: "HWC Lake Sesame Village",
#   street_address: "503, Jagruti Apts, Sainath Road, Malad (west)",
#   village_or_colony: "Lake Sesame Village",
#   district: "Alder County",
#   state: "Obsidian Province",
#   country: "India",
#   pin: "393180",
#   facility_type: "HWC",
#   created_at: Wed, 22 Jan 2020 07:31:36 IST +05:30,
#   updated_at: Wed, 22 Jan 2020 07:31:36 IST +05:30,
#   latitude: nil,
#   longitude: nil,
#   deleted_at: nil,
#   facility_group_id: "581d7cb1-4131-40ff-9dbb-33fc0683d34d",
#   slug: "hwc-lake-sesame-village",
#   zone: "Holly Grove",
#   enable_diabetes_management: true,
#   facility_size: "community",
#   monthly_estimated_opd_load: 300,
#   enable_teleconsultation: false>,

# FACILITY SIZES
#  Facility.facility_sizes
# => {"community"=>"community", "small"=>"small", "medium"=>"medium", "large"=>"large"}

# 3 major components
# (1) RegionService Class is composed of:
# - (2) the "brain", information generated by Repository class file (2)
# - (3) the "skeleton/body", that information is stored by the container made by Results class file, which sets up all the keys

# (byebug) pp @data_for_facility.entries[0]
# ["HWC Lake Sesame Village",
#  #<Reports::Result:0x00007fc169aec5e0
#   @current_period=<Period type:month value=2021-10-01>,
#   @data=
#    {"adjusted_patient_counts"=>
#      {<Period type:month value=2021-04-01>=>3,
#       <Period type:month value=2021-05-01>=>3,
#       <Period type:month value=2021-06-01>=>4,
#       <Period type:month value=2021-07-01>=>4,
#       <Period type:month value=2021-08-01>=>4,
#       <Period type:month value=2021-09-01>=>4},
#     "adjusted_patient_counts_with_ltfu"=>
#      {<Period type:month value=2021-04-01>=>3,
#       <Period type:month value=2021-05-01>=>3,
#       <Period type:month value=2021-06-01>=>4,
#       <Period type:month value=2021-07-01>=>4,
#       <Period type:month value=2021-08-01>=>4,
#       <Period type:month value=2021-09-01>=>4},
#     "assigned_patients"=>{},
#     "controlled_patients"=>
#      {<Period type:month value=2021-04-01>=>0,
#       <Period type:month value=2021-05-01>=>0,
#       <Period type:month value=2021-06-01>=>0,
#       <Period type:month value=2021-07-01>=>0,
#       <Period type:month value=2021-08-01>=>0,
#       <Period type:month value=2021-09-01>=>1},
#     "controlled_patients_rate"=>
#      {<Period type:month value=2021-04-01>=>0,
#       <Period type:month value=2021-05-01>=>0,
#       <Period type:month value=2021-06-01>=>0,
#       <Period type:month value=2021-07-01>=>0,
#       <Period type:month value=2021-08-01>=>0,
#       <Period type:month value=2021-09-01>=>25},
#     "controlled_patients_with_ltfu_rate"=>
#      {<Period type:month value=2021-04-01>=>0,
#       <Period type:month value=2021-05-01>=>0,
#       <Period type:month value=2021-06-01>=>0,
#       <Period type:month value=2021-07-01>=>0,
#       <Period type:month value=2021-08-01>=>0,
#       <Period type:month value=2021-09-01>=>25},
#     "cumulative_registrations"=>
#      {<Period type:month value=2021-04-01>=>4,
#       <Period type:month value=2021-05-01>=>4,
#       <Period type:month value=2021-06-01>=>4,
#       <Period type:month value=2021-07-01>=>5,
#       <Period type:month value=2021-08-01>=>5,
#       <Period type:month value=2021-09-01>=>5},
#     "cumulative_assigned_patients"=>
#      {<Period type:month value=2021-04-01>=>4,
#       <Period type:month value=2021-05-01>=>4,
#       <Period type:month value=2021-06-01>=>4,
#       <Period type:month value=2021-07-01>=>5,
#       <Period type:month value=2021-08-01>=>5,
#       <Period type:month value=2021-09-01>=>5},
#     "earliest_registration_period"=><Period type:month value=2020-07-01>,
#     "ltfu_patients"=>
#      {<Period type:month value=2021-04-01>=>0,
#       <Period type:month value=2021-05-01>=>0,
#       <Period type:month value=2021-06-01>=>0,
#       <Period type:month value=2021-07-01>=>0,
#       <Period type:month value=2021-08-01>=>0,
#       <Period type:month value=2021-09-01>=>0},
#     "ltfu_patients_rate"=>
#      {<Period type:month value=2021-04-01>=>0,
#       <Period type:month value=2021-05-01>=>0,
#       <Period type:month value=2021-06-01>=>0,
#       <Period type:month value=2021-07-01>=>0,
#       <Period type:month value=2021-08-01>=>0,
#       <Period type:month value=2021-09-01>=>0},
#     "missed_visits_rate"=>
#      {<Period type:month value=2021-04-01>=>67,
#       <Period type:month value=2021-05-01>=>67,
#       <Period type:month value=2021-06-01>=>50,
#       <Period type:month value=2021-07-01>=>75,
#       <Period type:month value=2021-08-01>=>75,
#       <Period type:month value=2021-09-01>=>50},
#     "missed_visits"=>
#      {<Period type:month value=2021-04-01>=>2,
#       <Period type:month value=2021-05-01>=>2,
#       <Period type:month value=2021-06-01>=>2,
#       <Period type:month value=2021-07-01>=>3,
#       <Period type:month value=2021-08-01>=>3,
#       <Period type:month value=2021-09-01>=>2},
#     "period_info"=>
#      {<Period type:month value=2021-04-01>=>
#        {"name"=>"Apr-2021",
#         "ltfu_since_date"=>"30-Apr-2020",
#         "bp_control_start_date"=>"1-Feb-2021",
#         "bp_control_end_date"=>"30-Apr-2021",
#         "bp_control_registration_date"=>"31-Jan-2021"},
#       <Period type:month value=2021-05-01>=>
#        {"name"=>"May-2021",
#         "ltfu_since_date"=>"31-May-2020",
#         "bp_control_start_date"=>"1-Mar-2021",
#         "bp_control_end_date"=>"31-May-2021",
#         "bp_control_registration_date"=>"28-Feb-2021"},
#       <Period type:month value=2021-06-01>=>
#        {"name"=>"Jun-2021",
#         "ltfu_since_date"=>"30-Jun-2020",
#         "bp_control_start_date"=>"1-Apr-2021",
#         "bp_control_end_date"=>"30-Jun-2021",
#         "bp_control_registration_date"=>"31-Mar-2021"},
#       <Period type:month value=2021-07-01>=>
#        {"name"=>"Jul-2021",
#         "ltfu_since_date"=>"31-Jul-2020",
#         "bp_control_start_date"=>"1-May-2021",
#         "bp_control_end_date"=>"31-Jul-2021",
#         "bp_control_registration_date"=>"30-Apr-2021"},
#       <Period type:month value=2021-08-01>=>
#        {"name"=>"Aug-2021",
#         "ltfu_since_date"=>"31-Aug-2020",
#         "bp_control_start_date"=>"1-Jun-2021",
#         "bp_control_end_date"=>"31-Aug-2021",
#         "bp_control_registration_date"=>"31-May-2021"},
#       <Period type:month value=2021-09-01>=>
#        {"name"=>"Sep-2021",
#         "ltfu_since_date"=>"30-Sep-2020",
#         "bp_control_start_date"=>"1-Jul-2021",
#         "bp_control_end_date"=>"30-Sep-2021",
#         "bp_control_registration_date"=>"30-Jun-2021"}},
#     "region"=>
#      #<Region:0x00007fc17006f9d0
#       id: "5c1c1471-e54b-41ac-9f2f-0739a203b397",
#       name: "HWC Lake Sesame Village",
#       slug: "hwc-lake-sesame-village",
#       description: nil,
#       source_type: "Facility",
#       source_id: "0fd2807e-06ee-470a-baad-287d0bd72904",
#       path:
#        "india.summit_heart_foundation.obsidian_province.alder_county.holly_grove.hwc_lake_sesame_village",
#       deleted_at: nil,
#       created_at: Mon, 20 Sep 2021 20:23:58 IST +05:30,
#       updated_at: Mon, 20 Sep 2021 20:23:58 IST +05:30,
#       region_type: "facility">,
#     "registrations"=>
#      {<Period type:month value=2021-04-01>=>0,
#       <Period type:month value=2021-05-01>=>0,
#       <Period type:month value=2021-06-01>=>0,
#       <Period type:month value=2021-07-01>=>1},
#     "uncontrolled_patients"=>
#      {<Period type:month value=2021-04-01>=>1,
#       <Period type:month value=2021-05-01>=>1,
#       <Period type:month value=2021-06-01>=>2,
#       <Period type:month value=2021-07-01>=>1,
#       <Period type:month value=2021-08-01>=>1,
#       <Period type:month value=2021-09-01>=>0},
#     "uncontrolled_patients_rate"=>
#      {<Period type:month value=2021-04-01>=>33,
#       <Period type:month value=2021-05-01>=>33,
#       <Period type:month value=2021-06-01>=>50,
#       <Period type:month value=2021-07-01>=>25,
#       <Period type:month value=2021-08-01>=>25,
#       <Period type:month value=2021-09-01>=>0},
#     "uncontrolled_patients_with_ltfu_rate"=>
#      {<Period type:month value=2021-04-01>=>33,
#       <Period type:month value=2021-05-01>=>33,
#       <Period type:month value=2021-06-01>=>50,
#       <Period type:month value=2021-07-01>=>25,
#       <Period type:month value=2021-08-01>=>25,
#       <Period type:month value=2021-09-01>=>0},
#     "visited_without_bp_taken"=>
#      {<Period type:month value=2021-04-01>=>0,
#       <Period type:month value=2021-05-01>=>0,
#       <Period type:month value=2021-06-01>=>0,
#       <Period type:month value=2021-07-01>=>0,
#       <Period type:month value=2021-08-01>=>0,
#       <Period type:month value=2021-09-01>=>1},
#     "visited_without_bp_taken_rates"=>
#      {<Period type:month value=2021-04-01>=>0,
#       <Period type:month value=2021-05-01>=>0,
#       <Period type:month value=2021-06-01>=>0,
#       <Period type:month value=2021-07-01>=>0,
#       <Period type:month value=2021-08-01>=>0,
#       <Period type:month value=2021-09-01>=>25},
#     "visited_without_bp_taken_with_ltfu_rates"=>
#      {<Period type:month value=2021-04-01>=>0,
#       <Period type:month value=2021-05-01>=>0,
#       <Period type:month value=2021-06-01>=>0,
#       <Period type:month value=2021-07-01>=>0,
#       <Period type:month value=2021-08-01>=>0,
#       <Period type:month value=2021-09-01>=>25},
#     "missed_visits_with_ltfu"=>
#      {<Period type:month value=2021-04-01>=>2,
#       <Period type:month value=2021-05-01>=>2,
#       <Period type:month value=2021-06-01>=>2,
#       <Period type:month value=2021-07-01>=>3,
#       <Period type:month value=2021-08-01>=>3,
#       <Period type:month value=2021-09-01>=>2},
#     "missed_visits_with_ltfu_rate"=>
#      {<Period type:month value=2021-04-01>=>67,
#       <Period type:month value=2021-05-01>=>67,
#       <Period type:month value=2021-06-01>=>50,
#       <Period type:month value=2021-07-01>=>75,
#       <Period type:month value=2021-08-01>=>75,
#       <Period type:month value=2021-09-01>=>50}},
#   @period_type=:month,
#   @quarterly_report=false,
#   @region=
#    #<Region:0x00007fc17006f9d0
#     id: "5c1c1471-e54b-41ac-9f2f-0739a203b397",
#     name: "HWC Lake Sesame Village",
#     slug: "hwc-lake-sesame-village",
#     description: nil,
#     source_type: "Facility",
#     source_id: "0fd2807e-06ee-470a-baad-287d0bd72904",
#     path:
#      "india.summit_heart_foundation.obsidian_province.alder_county.holly_grove.hwc_lake_sesame_village",
#     deleted_at: nil,
#     created_at: Mon, 20 Sep 2021 20:23:58 IST +05:30,
#     updated_at: Mon, 20 Sep 2021 20:23:58 IST +05:30,
#     region_type: "facility">>]

# (byebug) pp @stats_by_size
# {"community"=>
#   {"periods"=>
#     {<Period type:month value=2021-04-01>=>
#       {"controlled_patients"=>2,
#        "adjusted_patient_counts"=>43,
#        "cumulative_registrations"=>63,
#        "cumulative_assigned_patients"=>62,
#        "controlled_patients_rate"=>5},
#      <Period type:month value=2021-05-01>=>
#       {"controlled_patients"=>2,
#        "adjusted_patient_counts"=>48,
#        "cumulative_registrations"=>67,
#        "cumulative_assigned_patients"=>66,
#        "controlled_patients_rate"=>4},
#      <Period type:month value=2021-06-01>=>
#       {"controlled_patients"=>3,
#        "adjusted_patient_counts"=>48,
#        "cumulative_registrations"=>72,
#        "cumulative_assigned_patients"=>71,
#        "controlled_patients_rate"=>6},
#      <Period type:month value=2021-07-01>=>
#       {"controlled_patients"=>4,
#        "adjusted_patient_counts"=>51,
#        "cumulative_registrations"=>76,
#        "cumulative_assigned_patients"=>75,
#        "controlled_patients_rate"=>8},
#      <Period type:month value=2021-08-01>=>
#       {"controlled_patients"=>8,
#        "adjusted_patient_counts"=>54,
#        "cumulative_registrations"=>80,
#        "cumulative_assigned_patients"=>79,
#        "controlled_patients_rate"=>15},
#      <Period type:month value=2021-09-01>=>
#       {"controlled_patients"=>7,
#        "adjusted_patient_counts"=>58,
#        "cumulative_registrations"=>83,
#        "cumulative_assigned_patients"=>82,
#        "controlled_patients_rate"=>12}}},
#  "small"=>
#   {"periods"=>
#     {<Period type:month value=2021-04-01>=>
#       {"controlled_patients"=>2,
#        "adjusted_patient_counts"=>17,
#        "cumulative_registrations"=>27,
#        "cumulative_assigned_patients"=>27,
#        "controlled_patients_rate"=>12},
#      <Period type:month value=2021-05-01>=>
#       {"controlled_patients"=>2,
#        "adjusted_patient_counts"=>20,
#        "cumulative_registrations"=>27,
#        "cumulative_assigned_patients"=>27,
#        "controlled_patients_rate"=>10},
#      <Period type:month value=2021-06-01>=>
#       {"controlled_patients"=>1,
#        "adjusted_patient_counts"=>22,
#        "cumulative_registrations"=>28,
#        "cumulative_assigned_patients"=>28,
#        "controlled_patients_rate"=>5},
#      <Period type:month value=2021-07-01>=>
#       {"controlled_patients"=>0,
#        "adjusted_patient_counts"=>22,
#        "cumulative_registrations"=>29,
#        "cumulative_assigned_patients"=>29,
#        "controlled_patients_rate"=>0},
#      <Period type:month value=2021-08-01>=>
#       {"controlled_patients"=>1,
#        "adjusted_patient_counts"=>21,
#        "cumulative_registrations"=>30,
#        "cumulative_assigned_patients"=>30,
#        "controlled_patients_rate"=>5},
#      <Period type:month value=2021-09-01>=>
#       {"controlled_patients"=>2,
#        "adjusted_patient_counts"=>21,
#        "cumulative_registrations"=>32,
#        "cumulative_assigned_patients"=>32,
#        "controlled_patients_rate"=>10}}}}


# #<Reports::Repository:0x00007fd1dafc08d8
#  @bp_measures_query=#<BPMeasuresQuery:0x00007fd1dc85db70>,
#  @follow_ups_query=#<FollowUpsQuery:0x00007fd1dc87f900>,
#  @no_bp_measure_query=#<NoBPMeasureQuery:0x00007fd1dc87f8b0>,
#  @period_type=:month,
#  @periods=<Period type:month value=2019-10-01>..<Period type:month value=2021-09-01>,
#  @regions=
#   [#<Region:0x00007fd1dcb29110
#     id: "5c1c1471-e54b-41ac-9f2f-0739a203b397",
#     name: "HWC Lake Sesame Village",
#     slug: "hwc-lake-sesame-village",
#     description: nil,
#     source_type: "Facility",
#     source_id: "0fd2807e-06ee-470a-baad-287d0bd72904",
#     path: "india.summit_heart_foundation.obsidian_province.alder_county.holly_grove.hwc_lake_sesame_village",
#     deleted_at: nil,
#     created_at: Mon, 20 Sep 2021 14:53:58 UTC +00:00,
#     updated_at: Mon, 20 Sep 2021 14:53:58 UTC +00:00,
#     region_type: "facility">],
#  @registered_patients_query=#<RegisteredPatientsQuery:0x00007fd1dc87f888>,
#  @reporting_schema_v2=false,
#  @schema=
#   #<Reports::SchemaV1:0x00007fd1dafe85e0
#    @_memery_memoized_values=
#     {"controlled_70269659169160"=>
#       {[]=>
#         {:result=>
#           {"hwc-lake-sesame-village"=>
#             {<Period type:month value=2020-07-01>=>0,
#              <Period type:month value=2020-08-01>=>0,
#              <Period type:month value=2020-09-01>=>0,
#              <Period type:month value=2020-10-01>=>0,
#              <Period type:month value=2020-11-01>=>0,
#              <Period type:month value=2020-12-01>=>0,
#              <Period type:month value=2021-01-01>=>0,
#              <Period type:month value=2021-02-01>=>0,
#              <Period type:month value=2021-03-01>=>0,
#              <Period type:month value=2021-04-01>=>0,
#              <Period type:month value=2021-05-01>=>0,
#              <Period type:month value=2021-06-01>=>0,
#              <Period type:month value=2021-07-01>=>0,
#              <Period type:month value=2021-08-01>=>0,
#              <Period type:month value=2021-09-01>=>1}},
#          :time=>4849327.927034}},
#      "earliest_patient_recorded_at_period_70269659169160"=>
#       {[]=>{:result=>{"hwc-lake-sesame-village"=><Period type:month value=2020-07-01>}, :time=>4849327.728357}},
#      "earliest_patient_recorded_at_70269659169160"=>
#       {[]=>{:result=>{"hwc-lake-sesame-village"=>Tue, 28 Jul 2020 00:02:08 UTC +00:00}, :time=>4849327.72821}},
#      "cumulative_assigned_patients_70269659169160"=>
#       {[]=>
#         {:result=>
#           {"hwc-lake-sesame-village"=>
#             {<Period type:month value=2020-07-01>=>1,
#              <Period type:month value=2020-08-01>=>1,
#              <Period type:month value=2020-09-01>=>2,
#              <Period type:month value=2020-10-01>=>2,
#              <Period type:month value=2020-11-01>=>2,
#              <Period type:month value=2020-12-01>=>3,
#              <Period type:month value=2021-01-01>=>3,
#              <Period type:month value=2021-02-01>=>3,
#              <Period type:month value=2021-03-01>=>4,
#              <Period type:month value=2021-04-01>=>4,
#              <Period type:month value=2021-05-01>=>4,
#              <Period type:month value=2021-06-01>=>4,
#              <Period type:month value=2021-07-01>=>5,
#              <Period type:month value=2021-08-01>=>5,
#              <Period type:month value=2021-09-01>=>5}},
#          :time=>4849400.147148}},
#      "complete_monthly_assigned_patients_70269659169160"=>
#       {[]=>
#         {:result=>
#           {#<Reports::RegionEntry:0x00007fd1dc79aa30
#             @calculation=:complete_monthly_assigned_patients,
#             @options=[[:period_type, :month]],
#             @region=
#              #<Region:0x00007fd1dcb29110
#               id: "5c1c1471-e54b-41ac-9f2f-0739a203b397",
#               name: "HWC Lake Sesame Village",
#               slug: "hwc-lake-sesame-village",
#               description: nil,
#               source_type: "Facility",
#               source_id: "0fd2807e-06ee-470a-baad-287d0bd72904",
#               path: "india.summit_heart_foundation.obsidian_province.alder_county.holly_grove.hwc_lake_sesame_village",
#               deleted_at: nil,
#               created_at: Mon, 20 Sep 2021 14:53:58 UTC +00:00,
#               updated_at: Mon, 20 Sep 2021 14:53:58 UTC +00:00,
#               region_type: "facility">>=>
#             {<Period type:month value=2020-07-01>=>1,
#              <Period type:month value=2020-08-01>=>0,
#              <Period type:month value=2020-09-01>=>1,
#              <Period type:month value=2020-10-01>=>0,
#              <Period type:month value=2020-11-01>=>0,
#              <Period type:month value=2020-12-01>=>1,
#              <Period type:month value=2021-01-01>=>0,
#              <Period type:month value=2021-02-01>=>0,
#              <Period type:month value=2021-03-01>=>1,
#              <Period type:month value=2021-04-01>=>0,
#              <Period type:month value=2021-05-01>=>0,
#              <Period type:month value=2021-06-01>=>0,
#              <Period type:month value=2021-07-01>=>1}},
#          :time=>4849400.14602}},
#      "missed_visits_without_ltfu_rates_70269659169160"=>
#       {[]=>
#         {:result=>
#           {"hwc-lake-sesame-village"=>
#             {<Period type:month value=2020-07-01>=>0,
#              <Period type:month value=2020-08-01>=>0,
#              <Period type:month value=2020-09-01>=>0,
#              <Period type:month value=2020-10-01>=>100,
#              <Period type:month value=2020-11-01>=>100,
#              <Period type:month value=2020-12-01>=>0,
#              <Period type:month value=2021-01-01>=>50,
#              <Period type:month value=2021-02-01>=>50,
#              <Period type:month value=2021-03-01>=>100,
#              <Period type:month value=2021-04-01>=>67,
#              <Period type:month value=2021-05-01>=>67,
#              <Period type:month value=2021-06-01>=>50,
#              <Period type:month value=2021-07-01>=>75,
#              <Period type:month value=2021-08-01>=>75,
#              <Period type:month value=2021-09-01>=>50}},
#          :time=>4849926.165527}},
#      "ltfu_70269659169160"=>
#       {[]=>
#         {:result=>
#           {"hwc-lake-sesame-village"=>
#             {<Period type:month value=2020-07-01>=>0,
#              <Period type:month value=2020-08-01>=>0,
#              <Period type:month value=2020-09-01>=>0,
#              <Period type:month value=2020-10-01>=>0,
#              <Period type:month value=2020-11-01>=>0,
#              <Period type:month value=2020-12-01>=>0,
#              <Period type:month value=2021-01-01>=>0,
#              <Period type:month value=2021-02-01>=>0,
#              <Period type:month value=2021-03-01>=>0,
#              <Period type:month value=2021-04-01>=>0,
#              <Period type:month value=2021-05-01>=>0,
#              <Period type:month value=2021-06-01>=>0,
#              <Period type:month value=2021-07-01>=>0,
#              <Period type:month value=2021-08-01>=>0,
#              <Period type:month value=2021-09-01>=>0}},
#          :time=>4849925.249578}},
#      "missed_visits_without_ltfu_70269659169160"=>
#       {[]=>
#         {:result=>
#           {"hwc-lake-sesame-village"=>
#             {<Period type:month value=2020-07-01>=>0,
#              <Period type:month value=2020-08-01>=>0,
#              <Period type:month value=2020-09-01>=>0,
#              <Period type:month value=2020-10-01>=>1,
#              <Period type:month value=2020-11-01>=>1,
#              <Period type:month value=2020-12-01>=>0,
#              <Period type:month value=2021-01-01>=>1,
#              <Period type:month value=2021-02-01>=>1,
#              <Period type:month value=2021-03-01>=>3,
#              <Period type:month value=2021-04-01>=>2,
#              <Period type:month value=2021-05-01>=>2,
#              <Period type:month value=2021-06-01>=>2,
#              <Period type:month value=2021-07-01>=>3,
#              <Period type:month value=2021-08-01>=>3,
#              <Period type:month value=2021-09-01>=>2}},
#          :time=>4849926.148326}},
#      "uncontrolled_70269659169160"=>
#       {[]=>
#         {:result=>
#           {"hwc-lake-sesame-village"=>
#             {<Period type:month value=2020-07-01>=>0,
#              <Period type:month value=2020-08-01>=>0,
#              <Period type:month value=2020-09-01>=>0,
#              <Period type:month value=2020-10-01>=>0,
#              <Period type:month value=2020-11-01>=>0,
#              <Period type:month value=2020-12-01>=>2,
#              <Period type:month value=2021-01-01>=>1,
#              <Period type:month value=2021-02-01>=>1,
#              <Period type:month value=2021-03-01>=>0,
#              <Period type:month value=2021-04-01>=>1,
#              <Period type:month value=2021-05-01>=>1,
#              <Period type:month value=2021-06-01>=>2,
#              <Period type:month value=2021-07-01>=>1,
#              <Period type:month value=2021-08-01>=>1,
#              <Period type:month value=2021-09-01>=>0}},
#          :time=>4849925.431325}},
#      "visited_without_bp_taken_70269659169160"=>
#       {[]=>
#         {:result=>
#           {"hwc-lake-sesame-village"=>
#             {<Period type:month value=2020-07-01>=>0,
#              <Period type:month value=2020-08-01>=>0,
#              <Period type:month value=2020-09-01>=>0,
#              <Period type:month value=2020-10-01>=>0,
#              <Period type:month value=2020-11-01>=>0,
#              <Period type:month value=2020-12-01>=>0,
#              <Period type:month value=2021-01-01>=>0,
#              <Period type:month value=2021-02-01>=>0,
#              <Period type:month value=2021-03-01>=>0,
#              <Period type:month value=2021-04-01>=>0,
#              <Period type:month value=2021-05-01>=>0,
#              <Period type:month value=2021-06-01>=>0,
#              <Period type:month value=2021-07-01>=>0,
#              <Period type:month value=2021-08-01>=>0,
#              <Period type:month value=2021-09-01>=>1}},
#          :time=>4849926.129717}},
#      "cumulative_registrations_70269659169160"=>
#       {[]=>
#         {:result=>
#           {"hwc-lake-sesame-village"=>
#             {<Period type:month value=2020-07-01>=>1,
#              <Period type:month value=2020-08-01>=>1,
#              <Period type:month value=2020-09-01>=>2,
#              <Period type:month value=2020-10-01>=>2,
#              <Period type:month value=2020-11-01>=>2,
#              <Period type:month value=2020-12-01>=>3,
#              <Period type:month value=2021-01-01>=>3,
#              <Period type:month value=2021-02-01>=>3,
#              <Period type:month value=2021-03-01>=>4,
#              <Period type:month value=2021-04-01>=>4,
#              <Period type:month value=2021-05-01>=>4,
#              <Period type:month value=2021-06-01>=>4,
#              <Period type:month value=2021-07-01>=>5,
#              <Period type:month value=2021-08-01>=>5,
#              <Period type:month value=2021-09-01>=>5}},
#          :time=>5207968.935711}},
#      "complete_monthly_registrations_70269659169160"=>
#       {[]=>
#         {:result=>
#           {#<Reports::RegionEntry:0x00007fd1dc9e8ff8
#             @calculation=:complete_monthly_registrations,
#             @options=[[:period_type, :month]],
#             @region=
#              #<Region:0x00007fd1dcb29110
#               id: "5c1c1471-e54b-41ac-9f2f-0739a203b397",
#               name: "HWC Lake Sesame Village",
#               slug: "hwc-lake-sesame-village",
#               description: nil,
#               source_type: "Facility",
#               source_id: "0fd2807e-06ee-470a-baad-287d0bd72904",
#               path: "india.summit_heart_foundation.obsidian_province.alder_county.holly_grove.hwc_lake_sesame_village",
#               deleted_at: nil,
#               created_at: Mon, 20 Sep 2021 14:53:58 UTC +00:00,
#               updated_at: Mon, 20 Sep 2021 14:53:58 UTC +00:00,
#               region_type: "facility">>=>
#             {<Period type:month value=2020-07-01>=>1,
#              <Period type:month value=2020-08-01>=>0,
#              <Period type:month value=2020-09-01>=>1,
#              <Period type:month value=2020-10-01>=>0,
#              <Period type:month value=2020-11-01>=>0,
#              <Period type:month value=2020-12-01>=>1,
#              <Period type:month value=2021-01-01>=>0,
#              <Period type:month value=2021-02-01>=>0,
#              <Period type:month value=2021-03-01>=>1,
#              <Period type:month value=2021-04-01>=>0,
#              <Period type:month value=2021-05-01>=>0,
#              <Period type:month value=2021-06-01>=>0,
#              <Period type:month value=2021-07-01>=>1}},
#          :time=>5207968.933516}}},
#    @assigned_patients_query=#<AssignedPatientsQuery:0x00007fd1dc817738>,
#    @control_rate_query=#<ControlRateQuery:0x00007fd1dc82d7b8>,
#    @earliest_patient_data_query=#<EarliestPatientDataQuery:0x00007fd1dc2705c8>,
#    @no_bp_measure_query=#<NoBPMeasureQuery:0x00007fd1dc84c898>,
#    @period_type=:month,
#    @periods=<Period type:month value=2019-10-01>..<Period type:month value=2021-09-01>,
#    @regions=
#     [#<Region:0x00007fd1dcb29110
#       id: "5c1c1471-e54b-41ac-9f2f-0739a203b397",
#       name: "HWC Lake Sesame Village",
#       slug: "hwc-lake-sesame-village",
#       description: nil,
#       source_type: "Facility",
#       source_id: "0fd2807e-06ee-470a-baad-287d0bd72904",
#       path: "india.summit_heart_foundation.obsidian_province.alder_county.holly_grove.hwc_lake_sesame_village",
#       deleted_at: nil,
#       created_at: Mon, 20 Sep 2021 14:53:58 UTC +00:00,
#       updated_at: Mon, 20 Sep 2021 14:53:58 UTC +00:00,
#       region_type: "facility">],
#    @registered_patients_query=#<RegisteredPatientsQuery:0x00007fd1dc857608>>>
