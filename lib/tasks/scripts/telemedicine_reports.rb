# frozen_string_literal: true

require "csv"

module TelemedicineReports
  class << self
    def parse_mixpanel(mixpanel_csv_path)
      mixpanel_csv = File.read(mixpanel_csv_path)
      mixpanel = CSV.parse(mixpanel_csv, headers: false)

      mixpanel.drop(1).map { |row|
        facility = User.find(row[1]).registration_facility
        { user_id: row[1],
          date: Date.parse(row[2]),
          clicks: [row[3].to_i, row[4].to_i].max,
          facility_id: facility.id,
          district: facility.district,
          state: facility.state,
          type: facility.facility_type }
      }
    end

    def generate_report(mixpanel_data, period_start, period_end)
      period_mixpanel_data = format_mixpanel_data(mixpanel_data.select { |row| (row[:date] >= period_start) && (row[:date] <= period_end) })

      facilities = Facility.where(enable_teleconsultation: true).map { |facility|
        if (facility.facility_type == "HWC" || facility.facility_type == "SC")
          { id: facility.id,
            name: facility.name,
            state: facility.state,
            district: facility.district,
            type: facility.facility_type,
            period: facility_measures(facility, period_start, period_end),
            users: facility.users.count }
        else
          { id: facility.id,
            name: facility.name,
            state: facility.state,
            district: facility.district,
            type: facility.facility_type }
        end
      }

      facilities_data = format_facility_data(facilities)

      CSV.open("telemedicine_report_#{period_start.strftime("%d_%b")}_to_#{period_end.strftime("%d_%b")}.csv", "w") do |csv|
        csv << [
          "",
          "",
          "",
          "",
          "",
          "",
          "",
          "Between #{period_start.strftime("%d %b %Y")} and #{period_end.strftime("%d %b %Y")}",
          "",
          "",
          "",
          "",
          ""
        ]

        csv << [
          "State",
          "District",
          "Facility",
          "Facilities with TM",
          "HWCs & SCs with TM",
          "Users at HWCs & SCs",
          "",
          "Patients who visited",
          "Patients with High BP",
          "Patients with High Blood Sugar",
          "Patients with High BP or Sugar",
          "Teleconsult Button Clicks",
          "Teleconsult requests percentage"
        ]

        facilities_data.each do |state|
          period_clicks = fetch_clicks(period_mixpanel_data, state, true)
          csv << [
            state[:state],
            "",
            "",
            state[:count],
            state[:hwc_and_sc],
            state[:users],
            "",
            state[:period][:visits],
            state[:period][:high_bp],
            state[:period][:high_bs],
            state[:period][:high_bp_or_bs],
            period_clicks,
            percentage(period_clicks, state[:period][:high_bp_or_bs]),
          ]

          state[:districts].each do |district|
            period_clicks = fetch_clicks(period_mixpanel_data, district, false)
            csv << [
              "",
              district[:district],
              "",
              district[:count],
              district[:hwc_and_sc],
              district[:users],
              "",
              district[:period][:visits],
              district[:period][:high_bp],
              district[:period][:high_bs],
              district[:period][:high_bp_or_bs],
              period_clicks,
              percentage(period_clicks, district[:period][:high_bp_or_bs]),
            ]

            end
          end

        csv << []
        csv << []

        csv << [
          "",
          "",
          "",
          "",
          "",
          "",
          "",
          "Between #{period_start.strftime("%d %b %Y")} and #{period_end.strftime("%d %b %Y")}",
          "",
          "",
          "",
          "",
          ""
        ]

        csv << [
          "State",
          "District",
          "Facility",
          "Facilities with TM",
          "HWCs & SCs with TM",
          "Users at HWCs & SCs",
          "",
          "Patients who visited",
          "Patients with High BP",
          "Patients with High Blood Sugar",
          "Patients with High BP or Sugar",
          "Teleconsult Button Clicks",
          "Teleconsult requests percentage"
        ]

        facilities_data.each do |state|
          period_clicks = fetch_clicks(period_mixpanel_data, state, true)
          csv << [
            state[:state],
            "",
            "",
            state[:count],
            state[:hwc_and_sc],
            state[:users],
            "",
            state[:period][:visits],
            state[:period][:high_bp],
            state[:period][:high_bs],
            state[:period][:high_bp_or_bs],
            period_clicks,
            percentage(period_clicks, state[:period][:high_bp_or_bs]),
          ]

          state[:districts].each do |district|
            period_clicks = fetch_clicks(period_mixpanel_data, district, false)
            csv << [
              "",
              district[:district],
              "",
              district[:count],
              district[:hwc_and_sc],
              district[:users],
              "",
              district[:period][:visits],
              district[:period][:high_bp],
              district[:period][:high_bs],
              district[:period][:high_bp_or_bs],
              period_clicks,
              percentage(period_clicks, district[:period][:high_bp_or_bs]),
            ]

            district[:facilities].each do |facility|
              csv << [
                "",
                "",
                facility[:name],
                "",
                "",
                facility[:users],
                "",
                facility[:period][:visits],
                facility[:period][:high_bp],
                facility[:period][:high_bs],
                facility[:period][:high_bp_or_bs],
                "",
                ""
              ]
            end
          end
        end

        csv << []
        csv << []

        daily_activity_data = mixpanel_data.group_by { |row| row[:date] }.sort_by { |date, _rows| date }.map { |date, rows|
          [date.strftime("%d %b %Y"), rows.uniq { |row| row[:user_id] }.count, sum_rows(rows, :clicks)]
        }

        csv << ["Date", "Unique users", "Total TC requests"]
        daily_activity_data.each do |row|
          csv << row
        end
      end
    end

    private

    def format_mixpanel_data(period_data)
      period_data.group_by { |row| row[:state] }.map { |state, districts|
        { state: state,
          clicks: sum_rows(districts, :clicks),
          districts: districts.group_by { |row| row[:district] }.map { |district, users|
            { district: district,
              clicks: sum_rows(users, :clicks) }
          } }
      }
    end

    def format_facility_data(facility_data)
      facility_data.group_by { |row| row[:state] }.map { |state, districts|
        { state: state,
          count: districts.count,
          hwc_and_sc: hwc_and_sc_count(districts),
          period: aggregate_period(:period, districts),
          users: sum_rows(districts, :users),
          districts: districts.group_by { |row| row[:district] }.map { |district, facilities|
            { district: district,
              state: state,
              count: facilities.count,
              hwc_and_sc: hwc_and_sc_count(facilities),
              period: aggregate_period(:period, facilities),
              users: sum_rows(facilities, :users),
              facilities: facilities.select { |facility| %w[HWC SC].include? facility[:type] }.sort_by { |facility| facility[:name] } }
          }.sort_by { |district| district[:district] } }
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

      { high_bp: high_bps.count,
        high_bs: high_sugars.count,
        high_bp_or_bs: (high_bps + high_sugars).uniq { |record| record[:patient_id] }.count,
        visits: visits.count }
    end

    def sum_rows(rows, key)
      rows.compact.map { |row| row[key] || 0 }.sum
    end

    def hwc_and_sc_count(facilities)
      facilities.count { |facility| facility[:type] == "HWC" || facility[:type] == "SC" }
    end

    def aggregate_period(period, facilities)
      hwc_and_sc_data = facilities.map { |facility| facility[period] }
      { high_bp: sum_rows(hwc_and_sc_data, :high_bp),
        high_bs: sum_rows(hwc_and_sc_data, :high_bs),
        high_bp_or_bs: sum_rows(hwc_and_sc_data, :high_bp_or_bs),
        visits: sum_rows(hwc_and_sc_data, :visits) }
    end

    def fetch_clicks(data, record, is_state)
      if is_state
        return data.find { |state| state[:state] == record[:state] }&.dig(:clicks) || 0
      end
      districts = data.find { |state| state[:state] == record[:state] }&.dig(:districts) || []
      districts.find { |district| district[:district] == record[:district] }&.dig(:clicks) || 0
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
end
