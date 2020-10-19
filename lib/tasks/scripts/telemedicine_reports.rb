# frozen_string_literal: true

require "csv"

class TelemedicineReports
  attr_reader :mixpanel_csv_path, :period_start, :period_end, :mixpanel_data, :report_array

  def initialize(mixpanel_csv_path, period_start, period_end)
    @mixpanel_csv_path = mixpanel_csv_path
    @period_start = period_start
    @period_end = period_end
    @mixpanel_data = {hydrated: [], formatted: []}
    @report_array = []
  end

  def parse_mixpanel
    mixpanel_csv = File.read(@mixpanel_csv_path)
    mixpanel_data = CSV.parse(mixpanel_csv, headers: false)

    @mixpanel_data[:hydrated] = mixpanel_data.drop(1).map { |row|
      facility = User.find(row[1]).registration_facility
      {user_id: row[1],
       date: Date.parse(row[2]),
       clicks: row[3].to_i,
       facility_id: facility.id,
       district: facility.district,
       state: facility.state,
       type: facility.facility_type}
    }
  end

  def assemble_report_data
    @mixpanel_data[:hydrated] = @mixpanel_data[:hydrated].select { |row|
      (row[:date] >= @period_start) && (row[:date] <= @period_end)
    }
    @mixpanel_data[:formatted] = format_mixpanel_data(@mixpanel_data[:hydrated])

    facilities = Facility.where(enable_teleconsultation: true).map { |facility|
      if facility.facility_type == "HWC" || facility.facility_type == "SC"
        {id: facility.id,
         name: facility.name,
         state: facility.state,
         district: facility.district,
         type: facility.facility_type,
         telemed_data: facility_measures(facility, period_start, period_end),
         users: facility.users.count}
      else
        {id: facility.id,
         name: facility.name,
         state: facility.state,
         district: facility.district,
         type: facility.facility_type}
      end
    }

    facilities_data = format_facility_data(facilities)

    @report_array << [
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "Between #{period_start.strftime("%d-%b-%Y")} and #{period_end.strftime("%d-%b-%Y")}",
      "",
      "",
      "",
      "",
      ""
    ]

    @report_array << [
      "State",
      "District",
      "Facility",
      "Facilities with telemedicine",
      "HWCs & SCs with telemedicine",
      "Users of telemedicine",
      "",
      "Patients who visited",
      "Patients with High BP",
      "Patients with High Blood Sugar",
      "Patients with High BP or Sugar",
      "Teleconsult Button Clicks",
      "Teleconsultation MVP Requests",
      "Teleconsultation MVP Records logged by MOs",
      "Teleconsultation MVP Requests marked 'completed'",
      "Teleconsult requests percentage"
    ]

    facilities_data.each do |state|
      telemed_clicks = fetch_clicks_for_region(@mixpanel_data[:formatted], state, :state)
      @report_array << [
        state[:state],
        "",
        "",
        state[:count],
        state[:hwc_and_sc_count],
        state[:users],
        "",
        state[:telemed_data][:visits],
        state[:telemed_data][:high_bp],
        state[:telemed_data][:high_bs],
        state[:telemed_data][:high_bp_or_bs],
        telemed_clicks,
        state[:telemed_data][:teleconsultation_requests],
        state[:telemed_data][:teleconsultation_records],
        state[:telemed_data][:teleconsultation_marked_completed],
        percentage(telemed_clicks + state[:telemed_data][:teleconsultation_requests], state[:telemed_data][:high_bp_or_bs])
      ]

      state[:districts].each do |district|
        telemed_clicks = fetch_clicks_for_region(@mixpanel_data[:formatted], district, :district)
        @report_array << [
          "",
          district[:district],
          "",
          district[:count],
          district[:hwc_and_sc_count],
          district[:users],
          "",
          district[:telemed_data][:visits],
          district[:telemed_data][:high_bp],
          district[:telemed_data][:high_bs],
          district[:telemed_data][:high_bp_or_bs],
          telemed_clicks,
          district[:telemed_data][:teleconsultation_requests],
          district[:telemed_data][:teleconsultation_records],
          district[:telemed_data][:teleconsultation_marked_completed],
          percentage(telemed_clicks + district[:telemed_data][:teleconsultation_requests], district[:telemed_data][:high_bp_or_bs])
        ]
      end
    end

    @report_array << []
    @report_array << []

    @report_array << [
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "Between #{period_start.strftime("%d-%b-%Y")} and #{period_end.strftime("%d-%b-%Y")}",
      "",
      "",
      "",
      "",
      ""
    ]

    @report_array << [
      "State",
      "District",
      "Facility",
      "Facilities with telemedicine",
      "HWCs & SCs with telemedicine",
      "Users of telemedicine",
      "",
      "Patients who visited",
      "Patients with High BP",
      "Patients with High Blood Sugar",
      "Patients with High BP or Sugar",
      "Teleconsult Button Clicks",
      "Teleconsultation MVP Requests",
      "Teleconsultation MVP Records logged by MOs",
      "Teleconsultation MVP Requests marked 'completed'",
      "Teleconsult requests percentage"
    ]

    facilities_data.each do |state|
      telemed_clicks = fetch_clicks_for_region(@mixpanel_data[:formatted], state, :state)
      @report_array << [
        state[:state],
        "",
        "",
        state[:count],
        state[:hwc_and_sc_count],
        state[:users],
        "",
        state[:telemed_data][:visits],
        state[:telemed_data][:high_bp],
        state[:telemed_data][:high_bs],
        state[:telemed_data][:high_bp_or_bs],
        telemed_clicks,
        state[:telemed_data][:teleconsultation_requests],
        state[:telemed_data][:teleconsultation_records],
        state[:telemed_data][:teleconsultation_marked_completed],
        percentage(telemed_clicks + state[:telemed_data][:teleconsultation_requests], state[:telemed_data][:high_bp_or_bs])
      ]

      state[:districts].each do |district|
        telemed_clicks = fetch_clicks_for_region(@mixpanel_data[:formatted], district, :district)
        @report_array << [
          "",
          district[:district],
          "",
          district[:count],
          district[:hwc_and_sc_count],
          district[:users],
          "",
          district[:telemed_data][:visits],
          district[:telemed_data][:high_bp],
          district[:telemed_data][:high_bs],
          district[:telemed_data][:high_bp_or_bs],
          telemed_clicks,
          district[:telemed_data][:teleconsultation_requests],
          district[:telemed_data][:teleconsultation_records],
          district[:telemed_data][:teleconsultation_marked_completed],
          percentage(telemed_clicks + district[:telemed_data][:teleconsultation_requests], district[:telemed_data][:high_bp_or_bs])
        ]

        district[:facilities].each do |facility|
          @report_array << [
            "",
            "",
            facility[:name],
            "",
            "",
            facility[:users],
            "",
            facility[:telemed_data][:visits],
            facility[:telemed_data][:high_bp],
            facility[:telemed_data][:high_bs],
            facility[:telemed_data][:high_bp_or_bs],
            "",
            facility[:telemed_data][:teleconsultation_requests],
            facility[:telemed_data][:teleconsultation_records],
            facility[:telemed_data][:teleconsultation_marked_completed],
            ""
          ]
        end
      end
    end

    @report_array << []
    @report_array << []

    telemed_mvp_activity = Teleconsultation
      .where("device_created_at >= ? AND device_created_at <= ?", period_start, period_end)
      .group_by { |teleconsultation| teleconsultation.device_created_at.strftime("%d-%b-%Y") }

    old_telemed_activity = @mixpanel_data[:hydrated].group_by { |row| row[:date] }.sort_by { |date, _rows| date }.map { |date, rows|
      [date.strftime("%d-%b-%Y"), rows.uniq { |row| row[:user_id] }.count, sum_values(rows, :clicks)]
    }

    aggregate_telemed_activity = old_telemed_activity.map { |date, old_users, old_requests|
      [date,
        old_users,
        old_requests,
        telemed_mvp_activity.dig(date)&.map(&:requester_id)&.uniq&.count || 0,
        telemed_mvp_activity.dig(date)&.count || 0]
    }

    @report_array << ["Date", "Unique users for old telemed system", "TC requests from old telemed system", "Unique users for Telemed MVP", "TC requests from Telemed MVP"]
    aggregate_telemed_activity.each do |row|
      @report_array << row
    end
  end

  def write_csv
    CSV.open("telemedicine_report_#{@period_start.strftime("%d_%b")}_to_#{@period_end.strftime("%d_%b")}.csv", "w") do |csv|
      @report_array.each do |csv_row|
        csv << csv_row
      end
    end
  end

  def generate
    parse_mixpanel
    assemble_report_data
    write_csv
  end

  private

  def format_mixpanel_data(mixpanel_data)
    mixpanel_data.group_by { |row| row[:state] }.map { |state, districts|
      {state: state,
       clicks: sum_values(districts, :clicks),
       districts: districts.group_by { |row| row[:district] }.map { |district, users|
                    {district: district,
                     clicks: sum_values(users, :clicks)}
                  }}
    }
  end

  def format_facility_data(facility_data)
    facility_data.group_by { |facility| facility[:state] }.map { |state, state_facilities|
      {state: state,
       count: state_facilities.count,
       hwc_and_sc_count: hwc_and_sc_count(state_facilities),
       telemed_data: calculate_aggregates(state_facilities),
       users: sum_values(state_facilities, :users),
       districts: state_facilities.group_by { |facility| facility[:district] }.map { |district, district_facilities|
                    {district: district,
                     state: state,
                     count: district_facilities.count,
                     hwc_and_sc_count: hwc_and_sc_count(district_facilities),
                     telemed_data: calculate_aggregates(district_facilities),
                     users: sum_values(district_facilities, :users),
                     facilities: district_facilities
                       .select { |facility| %w[HWC SC].include? facility[:type] }
                       .sort_by { |facility| facility[:name] }}
                  }.sort_by { |district| district[:district] }}
    }.sort_by { |state| state[:state] }
  end

  def high_bps(bps)
    bps.hypertensive.uniq { |bp| bp[:patient_id] }
  end

  def high_sugars(blood_sugars)
    blood_sugars.select(&:diabetic?).uniq { |bs| bs[:patient_id] }
  end

  def facility_measures(facility, p_start, p_end)
    bps = facility.blood_pressures.where("recorded_at >= ? AND recorded_at <= ?", p_start, p_end)
    sugars = facility.blood_sugars.where("recorded_at >= ? AND recorded_at <= ?", p_start, p_end)
    appointments = facility.appointments.where("device_created_at >= ? AND device_created_at <= ?", p_start, p_end)
    drugs = facility.prescription_drugs.where("device_created_at >= ? AND device_created_at <= ?", p_start, p_end)
    visits = (bps + sugars + appointments + drugs).uniq { |record| record[:patient_id] }
    high_bps = high_bps(bps)
    high_sugars = high_sugars(sugars)
    teleconsult_mvp_requests = facility
      .teleconsultations
      .where("device_created_at >= ? AND device_created_at <= ?", p_start, p_end)
      .select("DISTINCT(patient_id)")
    teleconsult_mvp_records = teleconsult_mvp_requests.where.not(recorded_at: nil)
    teleconsult_mvp_marked_completed = teleconsult_mvp_requests.where(request_completed: "yes")

    {high_bp: high_bps.count,
     high_bs: high_sugars.count,
     high_bp_or_bs: (high_bps + high_sugars).uniq { |record| record[:patient_id] }.count,
     visits: visits.count,
     teleconsultation_requests: teleconsult_mvp_requests.count,
     teleconsultation_records: teleconsult_mvp_records.count,
     teleconsultation_marked_completed: teleconsult_mvp_marked_completed.count}
  end

  def sum_values(facilities, key)
    facilities.compact.map { |facility| facility[key] || 0 }.sum
  end

  def hwc_and_sc_count(facilities)
    facilities.count { |facility| facility[:type] == "HWC" || facility[:type] == "SC" }
  end

  def calculate_aggregates(facilities)
    hwcs_and_scs = facilities.map { |facility| facility[:telemed_data] }
    {high_bp: sum_values(hwcs_and_scs, :high_bp),
     high_bs: sum_values(hwcs_and_scs, :high_bs),
     high_bp_or_bs: sum_values(hwcs_and_scs, :high_bp_or_bs),
     visits: sum_values(hwcs_and_scs, :visits),
     teleconsultation_requests: sum_values(hwcs_and_scs, :teleconsultation_requests),
     teleconsultation_records: sum_values(hwcs_and_scs, :teleconsultation_records),
     teleconsultation_marked_completed: sum_values(hwcs_and_scs, :teleconsultation_marked_completed)}
  end

  def fetch_clicks_for_region(formatted_data, region, region_type)
    case region_type
    when :state
      formatted_data.find { |state| state[:state] == region[:state] }&.dig(:clicks) || 0
    when :district
      districts = formatted_data.find { |state| state[:state] == region[:state] }&.dig(:districts) || []
      districts.find { |district| district[:district] == region[:district] }&.dig(:clicks) || 0
    else
      0
    end
  end

  def percentage(numerator, denominator)
    return "NA" if denominator.nil? || denominator == 0 || numerator.nil?

    percentage = (numerator * 100.0) / denominator

    return "0%" if percentage.zero?
    return "NA" if percentage.infinite?
    return "< 1%" if percentage < 1

    "#{percentage.round(0)}%"
  end
end
