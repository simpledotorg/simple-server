# frozen_string_literal: true

require 'csv'

module TelemedicineReports
  def self.parse_mixpanel(mixpanel_csv_path, p1_start, p1_end, p2_start, p2_end)
    mixpanel_csv = open(mixpanel_csv_path)
    mixpanel = CSV.parse(mixpanel_csv, headers: false)


    click_data = mixpanel.drop(1).map { |row|
      facility = User.find(row[1]).registration_facility
      {user_id: row[1],
       date: Date.parse(row[2]),
       clicks: [row[3].to_i, row[4].to_i].max,
       facility_id: facility.id,
       district: facility.district,
       state: facility.state,
       type: facility.facility_type}
    }

    p1_click_data = format_click_data(click_data.select { |row|(row[:date] >= p1_start) && (row[:date] <= p1_end) })
    p2_click_data = format_click_data(click_data.select { |row|(row[:date] >= p2_start) && (row[:date] <= p2_end) })

    facilities = Facility.where(enable_teleconsultation: true).map do |facility|
      if facility.facility_type == "HWC" || facility.facility_type == "SC"
        {id: facility.id, state: facility.state, district: facility.district, type: facility.facility_type,
         p1: facility_measures(facility, p1_start, p1_end),
         p2: facility_measures(facility, p2_start, p2_end),
         users: facility.users.count}
      else
        {id: facility.id, state: facility.state, district: facility.district, type: facility.facility_type}
      end
    end

    facilities_data = format_facility_data(facilities)

    CSV.open("telemedicine_report.csv", "w") do |csv|
      csv << ["", "", "", "", "", "", "Between #{p1_start.strftime("%d %b %Y")} and #{p1_end.strftime("%d %b %Y")}", "", "",
              "", "", "", "Between #{p2_start.strftime("%d %b %Y")} and #{p2_end.strftime("%d %b %Y")}"]
      csv << ["State", "District", "Facilities with TM", "HWCs & SCs with TM", "Users at HWCs & SCs", "",
              "Patients who visited", "Patients with High BP", "Patients with High Blood Sugar", "Patients with High BP or Sugar", "Teleconsult Button Clicks", "",
              "Patients who visited", "Patients with High BP", "Patients with High Blood Sugar", "Patients with High BP or Sugar", "Teleconsult Button Clicks"]
      facilities_data.each do |state|
        csv << [state[:state], "", state[:count], state[:hwc_and_sc], state[:users], "",
                state[:p1][:visits], state[:p1][:high_bp], state[:p1][:high_bs], state[:p1][:high_bp_or_bs], fetch_clicks(p1_click_data, state, true), "",
                state[:p2][:visits], state[:p2][:high_bp], state[:p2][:high_bs], state[:p2][:high_bp_or_bs], fetch_clicks(p2_click_data, state, true)]

        state[:districts].each do |district|
          csv << ["", district[:district], district[:count], district[:hwc_and_sc], district[:users], "",
                  district[:p1][:visits], district[:p1][:high_bp], district[:p1][:high_bs], district[:p1][:high_bp_or_bs], fetch_clicks(p1_click_data, district, false), "",
                  district[:p2][:visits], district[:p2][:high_bp], district[:p2][:high_bs], district[:p2][:high_bp_or_bs], fetch_clicks(p2_click_data, district, false)]
        end
      end

      csv << ["", "", "", "", "", "", "", "", "", "", "", "", ""]
      csv << ["", "", "", "", "", "", "", "", "", "", "", "", ""]

      daily_activity_data = click_data.group_by { |row| row[:date] }.sort_by { |date, _rows| date }.map{ |date, rows|
                                [date.strftime("%d %b %Y"), rows.uniq { |row| row[:user_id] }.count, sum_rows(rows, :clicks)]
                              }
      csv << ["Date", "Unique users", "Total TC requests"]
      daily_activity_data.each do |row|
        csv << row
      end
    end
  end
end

def format_click_data(period_data)
  period_data.group_by { |row| row[:state] }.map { |state, districts|
    {state: state, clicks: sum_rows(districts, :clicks), districts: districts.group_by { |row|
      row[:district]
    }.map { |district, users|
      {district: district, clicks: sum_rows(users, :clicks)}
    }}
  }
end

def format_facility_data(facility_data)
  facility_data.group_by { |row| row[:state] }.map { |state, districts|
    {state: state, count: districts.count, hwc_and_sc: hwc_and_sc_count(districts),
     p1: aggregate_period(:p1, districts), p2: aggregate_period(:p2, districts),
     users: sum_rows(districts, :users)}},
     districts: districts.group_by { |row| row[:district] }.map { |district, facilities|
        {district: district, state: state, count: facilities.count, hwc_and_sc: hwc_and_sc_count(facilities),
         p1: aggregate_period(:p1, facilities), p2: aggregate_period(:p2, facilities),
         users: sum_rows(facilities, :users)}
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
  visits = (bps + sugars + appointments + drugs).uniq{ |record| record[:patient_id] }
  high_bps = high_bps(bps)
  high_sugars = high_sugars(sugars)

  {high_bp: high_bps.count,
   high_bs: high_sugars.count,
   high_bp_or_bs: (high_bps + high_sugars).uniq { |record| record[:patient_id] }.count,
   visits: visits.count}
end

def sum_rows(rows, key)
  rows.compact.map { |row| row[key] || 0 }.sum
end

def hwc_and_sc_count(facilities)
  facilities.count { |facility| facility[:type] == "HWC" || facility[:type] == "SC" }
end

def aggregate_period(period, facilities)
  hwc_and_sc_data = facilities.map { |facility| facility[period] }
  {high_bp: sum_rows(hwc_and_sc_data, :high_bp),
   high_bs: sum_rows(hwc_and_sc_data, :high_bs),
   high_bp_or_bs: sum_rows(hwc_and_sc_data, :high_bp_or_bs),
   visits: sum_rows(hwc_and_sc_data, :visits)}
end

def fetch_clicks(data, record, state)
  if state
    return data.find { |state| state[:state] == record[:state] }&.dig(:clicks) || 0
  end
  districts = data.find { |state| state[:state] == record[:state] }&.dig(:districts) || []
  districts.find { |district| district[:district] == record[:district] }&.dig(:clicks) || 0
end
