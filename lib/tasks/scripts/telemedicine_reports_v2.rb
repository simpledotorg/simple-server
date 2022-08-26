# frozen_string_literal: true

require "csv"

class TelemedicineReportsV2
  attr_reader :period_start, :period_end, :report_array

  def initialize(period_start, period_end)
    @period_start = period_start
    @period_end = period_end
    @report_array = []
    @filename = "telemedicine_report_#{@period_start.strftime("%d_%b")}_to_#{@period_end.strftime("%d_%b")}.csv"
  end

  def generate
    if Flipper.enabled?(:automated_telemed_report)
      assemble_report_data
      email_report
    end
  end

  private

  def email_report
    TelemedReportMailer
      .email_report(period_start: @period_start.strftime("%d_%b"),
        period_end: @period_end.strftime("%d_%b"),
        report_filename: @filename,
        report_csv: make_csv)
      .deliver_later
  end

  def assemble_report_data
    facilities = Facility.where(enable_teleconsultation: true).map { |facility|
      {id: facility.id,
       name: facility.name,
       state: facility.state,
       district: facility.district,
       type: facility.facility_type,
       size: facility.facility_size,
       telemed_data: facility_measures(facility, period_start, period_end),
       users: facility.users.count}
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
      "",
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
      "Community facilities with telemedicine",
      "Users of telemedicine",
      "",
      "Patients who visited",
      "Patients with High BP",
      "Patients with High Blood Sugar",
      "Patients with High BP or Sugar",
      "Teleconsult - Requests",
      "Teleconsult - Records logged by MOs",
      "Teleconsult - Requests marked completed",
      "Teleconsult - Requests marked incomplete",
      "Teleconsult - Requests marked waiting",
      "Teleconsult - Requests not marked (no completion status set)",
      "Teleconsult requests percentage"
    ]

    facilities_data.each do |state|
      @report_array << [
        state[:state],
        "",
        "",
        state[:count],
        state[:community_facilities_count],
        state[:users],
        "",
        state[:telemed_data][:visits],
        state[:telemed_data][:high_bp],
        state[:telemed_data][:high_bs],
        state[:telemed_data][:high_bp_or_bs],
        state[:telemed_data][:teleconsult_requests],
        state[:telemed_data][:teleconsult_records],
        state[:telemed_data][:teleconsult_marked_completed],
        state[:telemed_data][:teleconsult_marked_incomplete],
        state[:telemed_data][:teleconsult_marked_waiting],
        state[:telemed_data][:teleconsult_not_marked],
        percentage(state[:telemed_data][:teleconsult_requests], state[:telemed_data][:high_bp_or_bs])
      ]

      state[:districts].each do |district|
        @report_array << [
          "",
          district[:district],
          "",
          district[:count],
          district[:community_facilities_count],
          district[:users],
          "",
          district[:telemed_data][:visits],
          district[:telemed_data][:high_bp],
          district[:telemed_data][:high_bs],
          district[:telemed_data][:high_bp_or_bs],
          district[:telemed_data][:teleconsult_requests],
          district[:telemed_data][:teleconsult_records],
          district[:telemed_data][:teleconsult_marked_completed],
          district[:telemed_data][:teleconsult_marked_incomplete],
          district[:telemed_data][:teleconsult_marked_waiting],
          district[:telemed_data][:teleconsult_not_marked],
          percentage(district[:telemed_data][:teleconsult_requests], district[:telemed_data][:high_bp_or_bs])
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
      "",
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
      "Community facilities with telemedicine",
      "Users of telemedicine",
      "",
      "Patients who visited",
      "Patients with High BP",
      "Patients with High Blood Sugar",
      "Patients with High BP or Sugar",
      "Teleconsult - Requests",
      "Teleconsult - Records logged by MOs",
      "Teleconsult - Requests marked completed",
      "Teleconsult - Requests marked incomplete",
      "Teleconsult - Requests marked waiting",
      "Teleconsult - Requests not marked (no completion status set)",
      "Teleconsult requests percentage"
    ]

    facilities_data.each do |state|
      @report_array << [
        state[:state],
        "",
        "",
        state[:count],
        state[:community_facilities_count],
        state[:users],
        "",
        state[:telemed_data][:visits],
        state[:telemed_data][:high_bp],
        state[:telemed_data][:high_bs],
        state[:telemed_data][:high_bp_or_bs],
        state[:telemed_data][:teleconsult_requests],
        state[:telemed_data][:teleconsult_records],
        state[:telemed_data][:teleconsult_marked_completed],
        state[:telemed_data][:teleconsult_marked_incomplete],
        state[:telemed_data][:teleconsult_marked_waiting],
        state[:telemed_data][:teleconsult_not_marked],
        percentage(state[:telemed_data][:teleconsult_requests], state[:telemed_data][:high_bp_or_bs])
      ]

      state[:districts].each do |district|
        @report_array << [
          "",
          district[:district],
          "",
          district[:count],
          district[:community_facilities_count],
          district[:users],
          "",
          district[:telemed_data][:visits],
          district[:telemed_data][:high_bp],
          district[:telemed_data][:high_bs],
          district[:telemed_data][:high_bp_or_bs],
          district[:telemed_data][:teleconsult_requests],
          district[:telemed_data][:teleconsult_records],
          district[:telemed_data][:teleconsult_marked_completed],
          district[:telemed_data][:teleconsult_marked_incomplete],
          district[:telemed_data][:teleconsult_marked_waiting],
          district[:telemed_data][:teleconsult_not_marked],
          percentage(district[:telemed_data][:teleconsult_requests], district[:telemed_data][:high_bp_or_bs])
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
            facility[:telemed_data][:teleconsult_requests],
            facility[:telemed_data][:teleconsult_records],
            facility[:telemed_data][:teleconsult_marked_completed],
            facility[:telemed_data][:teleconsult_marked_incomplete],
            facility[:telemed_data][:teleconsult_marked_waiting],
            facility[:telemed_data][:teleconsult_not_marked],
            percentage(facility[:telemed_data][:teleconsult_requests], facility[:telemed_data][:high_bp_or_bs])
          ]
        end
      end
    end

    @report_array << []
    @report_array << []

    requests_per_day = Teleconsultation
      .where("device_created_at >= ? AND device_created_at <= ?", period_start, period_end)
      .group_by_period(:day, :device_created_at, format: "%d-%b-%Y")
      .count

    users_per_day = Teleconsultation
      .where("device_created_at >= ? AND device_created_at <= ?", period_start, period_end)
      .select("requester_id")
      .distinct
      .group_by_period(:day, :device_created_at, format: "%d-%b-%Y")
      .count

    daily_activity_data = users_per_day
      .merge(requests_per_day) { |_date, users, requests| [users, requests] }
      .map(&:flatten)

    @report_array << ["Date", "Unique users", "Total TC requests"]
    daily_activity_data.each do |row|
      @report_array << row
    end
  end

  def make_csv
    CSV.generate do |csv|
      @report_array.each do |csv_row|
        csv << csv_row
      end
    end
  end

  def format_facility_data(facility_data)
    facility_data.group_by { |facility| facility[:state] }.map { |state, state_facilities|
      {state: state,
       count: state_facilities.count,
       community_facilities_count: community_facilities_count(state_facilities),
       telemed_data: calculate_aggregates(state_facilities),
       users: sum_values(state_facilities, :users),
       districts: state_facilities.group_by { |facility| facility[:district] }.map { |district, district_facilities|
                    {district: district,
                     state: state,
                     count: district_facilities.count,
                     community_facilities_count: community_facilities_count(district_facilities),
                     telemed_data: calculate_aggregates(district_facilities),
                     users: sum_values(district_facilities, :users),
                     facilities: district_facilities
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
    teleconsult_requests = facility
      .teleconsultations
      .where("device_created_at >= ? AND device_created_at <= ?", p_start, p_end)
      .select("DISTINCT ON (patient_id) patient_id, requester_completion_status, recorded_at")
      .order(Arel.sql("patient_id, array_position(array['yes', 'no', 'waiting']::varchar[], requester_completion_status)"))
      .to_a
    teleconsult_records = teleconsult_requests.reject { |request| request.recorded_at.nil? }
    teleconsult_marked_completed = teleconsult_requests.select { |request| request.requester_completion_status == "yes" }
    teleconsult_marked_incomplete = teleconsult_requests.select { |request| request.requester_completion_status == "no" }
    teleconsult_marked_waiting = teleconsult_requests.select { |request| request.requester_completion_status == "waiting" }
    teleconsult_not_marked = teleconsult_requests.select { |request| request.requester_completion_status.nil? }

    {high_bp: high_bps.count,
     high_bs: high_sugars.count,
     high_bp_or_bs: (high_bps + high_sugars).uniq { |record| record[:patient_id] }.count,
     visits: visits.count,
     teleconsult_requests: teleconsult_requests.count,
     teleconsult_records: teleconsult_records.count,
     teleconsult_marked_completed: teleconsult_marked_completed.count,
     teleconsult_marked_incomplete: teleconsult_marked_incomplete.count,
     teleconsult_marked_waiting: teleconsult_marked_waiting.count,
     teleconsult_not_marked: teleconsult_not_marked.count}
  end

  def sum_values(facilities, key)
    facilities.compact.map { |facility| facility[key] || 0 }.sum
  end

  def community_facilities_count(facilities)
    facilities.count { |facility| facility[:size] == "community" }
  end

  def calculate_aggregates(facilities)
    facilities = facilities.map { |facility| facility[:telemed_data] }
    {high_bp: sum_values(facilities, :high_bp),
     high_bs: sum_values(facilities, :high_bs),
     high_bp_or_bs: sum_values(facilities, :high_bp_or_bs),
     visits: sum_values(facilities, :visits),
     teleconsult_requests: sum_values(facilities, :teleconsult_requests),
     teleconsult_records: sum_values(facilities, :teleconsult_records),
     teleconsult_marked_completed: sum_values(facilities, :teleconsult_marked_completed),
     teleconsult_marked_incomplete: sum_values(facilities, :teleconsult_marked_incomplete),
     teleconsult_marked_waiting: sum_values(facilities, :teleconsult_marked_waiting),
     teleconsult_not_marked: sum_values(facilities, :teleconsult_not_marked)}
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
