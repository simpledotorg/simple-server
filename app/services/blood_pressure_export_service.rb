class BloodPressureExportService

  include ActionView::Helpers::NumberHelper
  include DashboardHelper
  require 'csv'

  attr_reader :start_period, :end_period, :facilities, :data_type, :data_for_facility, :stats_by_size

  def initialize(data_type:, start_period:, end_period:, facilities:)
    @data_type = data_type
    @start_period = start_period
    @end_period = end_period
    @facilities = facilities

    @data_for_facility = {}
    facilities.each do |facility|
      @data_for_facility[facility.name] = Reports::RegionService.new(
        region: facility.region, period: @end_period, months: 6
      ).call
    end
    # sizes = @data_for_facility.map { |_, facility| facility.region.source.facility_size }.uniq
    # @display_sizes = @facility_sizes.select { |size| sizes.include? size }
    @stats_by_size = FacilityStatsService.call(facilities: @data_for_facility, period: @end_period, rate_numerator: data_type) end
  def call
    {}
  end
  # def self.hello 
  #   "HELLO I EXIST"
  # end

  def generate_csv(data_name) ### abstracted csv stuff to this code, will in order to be executed above
    return CSV.generate(){ |csv|
      headers = ["Facilities", "Total assigned", "Total registered","6-month change"]
      (@start_period..@period).each {|period| headers << period << "Ratio" } # Monthly percentage headers, Monthly ratio headers
      csv << headers

      @display_sizes.each_with_index do |size, i| #For loop for the top row/ Sites of that size
        row = []
        facility_size_six_month_rate_change = facility_size_six_month_rate_change(@stats_by_size[size][:periods], "#{data_name}_rate")
        row << "All #{Facility.localized_facility_size(size)}s" # Facilities
        row << number_or_zero_with_delimiter(@stats_by_size[size][:periods][@period][:cumulative_assigned_patients]) #Assigned
        row << number_or_zero_with_delimiter(@stats_by_size[size][:periods][@period][:cumulative_registrations]) # Registered
        row <<  number_to_percentage_with_symbol(facility_size_six_month_rate_change, precision: 0) #6 month change
        @stats_by_size[size][:periods].each_pair do |period, data| 
          data_name_rate = data["#{data_name}_rate"]
          row << number_to_percentage(data_name_rate || 0, precision: 0) #Monthly rate change
          row << "#{data[data_name]} / #{data["adjusted_patient_counts"]}" #Monthly ratio
        end
        csv << row
        @data_for_facility.each do |_, facility_data| #Hash iterator for subsequent rows
          sub_row = []
          facility = facility_data.region.source
          next if facility.facility_size != size
          six_month_rate_change = six_month_rate_change(facility, "#{data_name}_rate")
          sub_row << facility.name # Facility name
          sub_row << number_or_zero_with_delimiter(facility_data["cumulative_assigned_patients"].values.last) # Assigned
          sub_row << number_or_zero_with_delimiter(facility_data["cumulative_registrations"].values.last) # Registered
          sub_row << number_to_percentage_with_symbol(six_month_rate_change, precision: 0) # 6 month change
          (@start_period..@period).each do |period|
            data_name_rate = facility_data["#{data_name}_rate"][period] #redeclaring this variable for the inner loop we are using
            sub_row << number_to_percentage(data_name_rate || 0, precision: 0) #Monthly rate
            sub_row << "#{facility_data[data_name][period]} / #{facility_data["adjusted_patient_counts"][period]}" #Monthly ratio
          end
          csv << sub_row
        end
        csv << [] if i != @display_sizes.length-1 #Partition between the facility sizes, for clarity
      end
    }
  end

  def process_facility_stats(type)
    @data_for_facility = {}

    facilities.each do |facility|
      @data_for_facility[facility.name] = Reports::RegionService.new(
        region: facility.region, period: @period, months: 6
      ).call
    end
    # sizes = @data_for_facility.map { |_, facility| facility.region.source.facility_size }.uniq
    # @display_sizes = @facility_sizes.select { |size| sizes.include? size }
    @stats_by_size = FacilityStatsService.call(facilities: @data_for_facility, period: @period, rate_numerator: type)
  end

end

  #DATA WE WANT IS:
  #facility_name
  # cumulative_assigned_patients 
  # cumulative_registrations
  # 6 month change
  # data_type #controlled_patients / uncontrolled_patients / missed_visits
  # adjusted_patient_counts
  # data_rate #controlled_patients_rate / uncontrolled_patients_rate / missed_visits_rate

  # def format_processed_stats_to_csv_rows(type)
  #   process_facility_stats(type)
  #   formatted = {}
  #   formatted["headers"] = set_csv_headers
  #   @display_sizes.each do |size|
  #     if !formatted[size]
  #       formatted[size] = {}
  #       formatted[size]["aggregate"] = {format_aggregate_facility_stats(type)}
  #       formatted[size]["facilities"] = []
  #     end
      



  #   end

  # end

  # def set_csv_headers
  #   headers = ["Facilities", "Total assigned", "Total registered","6-month change"]
  #   (@start_period..@period).each {|period| headers << period << "Ratio" }
  #   headers
  # end

  # def format_aggregate_facility_stats(type)
  #   #should i use object or array?
  #   aggregate_row = {}
  #   facility_size_six_month_rate_change = facility_size_six_month_rate_change(@stats_by_size[size][:periods], "#{type}_rate")
  #   aggregate_row["Facilities"] = "All #{Facility.localized_facility_size(size)}s"
  #   aggregate_row["total_assigned"] << number_or_zero_with_delimiter(@stats_by_size[size][:periods][@period][:cumulative_assigned_patients])
  #   aggregate_row["total_registered"] << number_or_zero_with_delimiter(@stats_by_size[size][:periods][@period][:cumulative_registrations])
  #   aggregate_row["six_month_change"] <<  number_to_percentage_with_symbol(facility_size_six_month_rate_change, precision: 0)
  #   @stats_by_size[size][:periods].each_pair do |period, data| 
  #     #figure this part out
  #     type_rate = data["#{type}_rate"]
  #     aggregate_row["Facilities"] << number_to_percentage(type_rate || 0, precision: 0)
  #     aggregate_row["Facilities"] << "#{data[type]} / #{data["adjusted_patient_counts"]}"
  #   end
  # end

  # def format_subsequent_stats(type)
  #   @data_for_facility.each do |_, facility_data| #Hash iterator for subsequent rows
  #     sub_row = []
  #     facility = facility_data.region.source
  #     next if facility.facility_size != size
  #     six_month_rate_change = six_month_rate_change(facility, "#{type}_rate")
  #     sub_row << facility.name # Facility name
  #     sub_row << number_or_zero_with_delimiter(facility_data["cumulative_assigned_patients"].values.last) # Assigned
  #     sub_row << number_or_zero_with_delimiter(facility_data["cumulative_registrations"].values.last) # Registered
  #     sub_row << number_to_percentage_with_symbol(six_month_rate_change, precision: 0) # 6 month change
  #     (@start_period..@period).each do |period|
  #       type_rate = facility_data["#{type}_rate"][period] #redeclaring this variable for the inner loop we are using
  #       sub_row << number_to_percentage(type_rate || 0, precision: 0) #Monthly rate
  #       sub_row << "#{facility_data[type][period]} / #{facility_data["adjusted_patient_counts"][period]}" #Monthly ratio
  #     end
  #   end
  # end


# {
#   large: [
#     aggregate: { name_tag: "All SDH/DHs", controlled_rate: "4,802", controlled_numerater: , controlled_demoninator: }
#     facilities: [
#       { name_tag: "All SDH/DHs", controlled_rate: "4,802", controlled_numerater: , controlled_demoninator: }
#     ]
#   ]
# }

#filter_facilities returns this array of facilities depending on current admin user
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


#FACILITY SIZES
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