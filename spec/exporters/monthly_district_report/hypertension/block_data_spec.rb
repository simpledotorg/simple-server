require "rails_helper"

def setup_district_data
  organization = FactoryBot.create(:organization)
  facility_group = create(:facility_group, organization: organization)
  facility1 = create(:facility, name: "Test Facility 1", block: "Test Block 1", facility_group: facility_group)
  facility2 = create(:facility, name: "Test Facility 2", block: "Test Block 2", facility_group: facility_group)

  create(:patient, :hypertension, recorded_at: 3.months.ago, assigned_facility: facility1, registration_facility: facility1)

  follow_up_patient = create(:patient, :hypertension, recorded_at: 3.months.ago, assigned_facility: facility2, registration_facility: facility2)
  create(:appointment, creation_facility: facility2, scheduled_date: 2.month.ago, patient: follow_up_patient)
  create(:bp_with_encounter, :under_control, facility: facility2, patient: follow_up_patient, recorded_at: 2.months.ago)

  create(:patient, :without_diabetes, recorded_at: 2.months.ago, assigned_facility: facility1, registration_facility: facility1)

  create(:patient, :hypertension, recorded_at: 2.years.ago, assigned_facility: facility1, registration_facility: facility1)

  # medications_dispensed_patients
  create(:appointment, facility: facility1, scheduled_date: 10.days.from_now, device_created_at: Date.today, patient: create(:patient, :hypertension, recorded_at: 4.months.ago, registration_facility: facility1))
  create(:appointment, facility: facility2, scheduled_date: 10.days.from_now, device_created_at: Date.today, patient: create(:patient, :hypertension, recorded_at: 4.months.ago, registration_facility: facility2))
  create(:appointment, facility: facility2, scheduled_date: Date.today, device_created_at: 32.days.ago, patient: create(:patient, :hypertension, recorded_at: 4.months.ago, registration_facility: facility2))
  create(:appointment, facility: facility1, scheduled_date: Date.today, device_created_at: 63.days.ago, patient: create(:patient, :hypertension, recorded_at: 4.months.ago, registration_facility: facility1))

  RefreshReportingViews.refresh_v2

  {region: facility_group.region}
end

describe MonthlyDistrictReport::Hypertension::BlockData do
  context "#header_rows" do
    it "returns a list of header rows with the correct number of columns" do
      district = setup_district_with_facilities
      month = Period.month("2021-09-01".to_date)
      header_rows = described_class.new(district[:region], month).header_rows
      expect(header_rows[0].count).to eq 39
      expect(header_rows[1].count).to eq 39
    end
  end

  context "#content_rows" do
    it "returns a hash with the required keys and values" do
      Timecop.freeze("2022-07-31") do
        district_data = setup_district_data
        today = Date.today
        month = Period.month(today)
        periods = Range.new(month.advance(months: -5), month)

        rows = described_class.new(district_data[:region], month).content_rows

        expect(rows[0].count).to eq 39

        expect(rows[0]["Blocks"]).to eq "Test Block 1"
        expect(rows[0]["Total hypertension registrations"]).to eq 4
        expect(rows[0]["Total assigned hypertension patients"]).to eq 4
        expect(rows[0]["Total hypertension patients under care"]).to eq 3
        expect(rows[0]["Total hypertension patients lost to followup"]).to eq 1
        expect(rows[0]["% BP controlled"]).to eq "0%"
        expect(rows[0]["% BP uncontrolled"]).to eq "0%"
        expect(rows[0]["% Missed Visits"]).to eq "33%"
        expect(rows[0]["% Visits, no BP taken"]).to eq "67%"

        expect(periods.map { |period| rows[0]["cumulative_registrations - #{period}"] }).to eq [1, 3, 4, 4, 4, 4]
        expect(periods.map { |period| rows[0]["under_care - #{period}"] }).to eq [0, 2, 3, 3, 3, 3]
        expect(periods.map { |period| rows[0]["monthly_registrations - #{period}"] }).to eq [0, 2, 1, 0, 0, 0]
        expect(periods.map { |period| rows[0]["hypertension_follow_ups - #{period}"] }).to eq [0, 0, 0, 1, 0, 1]
        expect(periods.map { |period| rows[0]["controlled_rates - #{period}"] }).to eq %w[0% 0% 0% 0% 0% 0%]

        expect(rows[1]["Blocks"]).to eq "Test Block 2"
        expect(rows[1]["Total hypertension registrations"]).to eq 3
        expect(rows[1]["Total assigned hypertension patients"]).to eq 3
        expect(rows[1]["Total hypertension patients under care"]).to eq 3
        expect(rows[1]["Total hypertension patients lost to followup"]).to eq 0
        expect(rows[1]["% BP controlled"]).to eq "33%"
        expect(rows[1]["% BP uncontrolled"]).to eq "0%"
        expect(rows[1]["% Missed Visits"]).to eq "0%"
        expect(rows[1]["% Visits, no BP taken"]).to eq "67%"
        expect(periods.map { |period| rows[1]["cumulative_registrations - #{period}"] }).to eq [0, 2, 3, 3, 3, 3]
        expect(periods.map { |period| rows[1]["under_care - #{period}"] }).to eq [0, 2, 3, 3, 3, 3]
        expect(periods.map { |period| rows[1]["controlled_rates - #{period}"] }).to eq %w[0% 0% 0% 0% 0% 33%]
        expect(periods.map { |period| rows[1]["monthly_registrations - #{period}"] }).to eq [0, 2, 1, 0, 0, 0]
        expect(periods.map { |period| rows[1]["hypertension_follow_ups - #{period}"] }).to eq [0, 0, 0, 1, 1, 2]
      end
    end

    it "orders the rows by block names" do
      district = setup_district_with_facilities
      month = Period.month("2021-09-01".to_date)
      rows = described_class.new(district[:region], month).content_rows
      expect(rows.map { |row| row["Blocks"] }).to match_array ["Test Block 1", "Test Block 2"]
    end
  end
end
