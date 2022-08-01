require "rails_helper"

describe MonthlyDistrictReport::Diabetes::BlockData do
  def setup_district_data
    organization = FactoryBot.create(:organization)
    facility_group = create(:facility_group, organization: organization)
    facility1 = create(:facility, name: "Facility 1", block: "Block 1 - alphabetically first", facility_group: facility_group, facility_size: :community, enable_diabetes_management: true)
    facility2 = create(:facility, name: "Facility 2", block: "Block 2 - alphabetically second", facility_group: facility_group, facility_size: :community, enable_diabetes_management: true)

    create(:patient, :diabetes, recorded_at: 3.months.ago, assigned_facility: facility1, registration_facility: facility1)

    follow_up_patient = create(:patient, :diabetes, recorded_at: 3.months.ago, assigned_facility: facility2, registration_facility: facility2)
    create(:appointment, creation_facility: facility2, scheduled_date: 2.month.ago, patient: follow_up_patient)
    create(:blood_sugar_with_encounter, :bs_below_200, facility: facility2, patient: follow_up_patient, recorded_at: 2.months.ago)

    create(:patient, :without_diabetes, recorded_at: 2.months.ago, assigned_facility: facility1, registration_facility: facility1)

    create(:patient, :diabetes, recorded_at: 2.years.ago, assigned_facility: facility1, registration_facility: facility1)

    # medications_dispensed_patients
    create(:appointment, facility: facility1, scheduled_date: 10.days.from_now, device_created_at: Date.today, patient: create(:patient, :diabetes, recorded_at: 4.months.ago, registration_facility: facility1))
    create(:appointment, facility: facility2, scheduled_date: 10.days.from_now, device_created_at: Date.today, patient: create(:patient, :diabetes, recorded_at: 4.months.ago, registration_facility: facility2))
    create(:appointment, facility: facility2, scheduled_date: Date.today, device_created_at: 32.days.ago, patient: create(:patient, :diabetes, recorded_at: 4.months.ago, registration_facility: facility2))
    create(:appointment, facility: facility1, scheduled_date: Date.today, device_created_at: 63.days.ago, patient: create(:patient, :diabetes, recorded_at: 4.months.ago, registration_facility: facility1))

    RefreshReportingViews.refresh_v2

    {region: facility_group.region}
  end

  context "#header_rows" do
    it "returns a list of header rows with the correct number of columns" do
      district = setup_district_with_facilities
      month = Period.month("2021-09-01".to_date)
      header_rows = described_class.new(district[:region], month).header_rows

      expect(header_rows[0].count).to eq 52
      expect(header_rows[1].count).to eq 52
    end
  end

  context "#content_rows" do
    it "returns a hash with the required keys and values" do
      Timecop.freeze("2022-07-31") do
        month = Period.month(Period.current)
        periods = Range.new(month.advance(months: -5), month)
        region = setup_district_data[:region]

        rows = described_class.new(region, month).content_rows

        expect(rows[0].count).to eq 52

        expect(rows[0]["Blocks"]).to eq "Block 1 - alphabetically first"
        expect(rows[0]["Total diabetes registrations"]).to eq 4
        expect(rows[0]["Total assigned diabetes patients"]).to eq 4
        expect(rows[0]["Total diabetes patients under care"]).to eq 3
        expect(rows[0]["Total diabetes patients lost to followup"]).to eq 1
        expect(rows[0]["% Blood sugar below 200"]).to eq "0%"
        expect(rows[0]["% Blood sugar between 200 and 300"]).to eq "0%"
        expect(rows[0]["% Blood sugar over 300"]).to eq "0%"
        expect(rows[0]["% Diabetes missed Visits"]).to eq "33%"
        expect(rows[0]["% Visits, no blood sugar taken"]).to eq "67%"

        expect(periods.map { |period| rows[0]["cumulative_diabetes_registrations - #{period}"] }).to eq [1, 3, 4, 4, 4, 4]
        expect(periods.map { |period| rows[0]["diabetes_under_care - #{period}"] }).to eq [0, 2, 3, 3, 3, 3]
        expect(periods.map { |period| rows[0]["monthly_diabetes_registrations - #{period}"] }).to eq [0, 2, 1, 0, 0, 0]
        expect(periods.map { |period| rows[0]["diabetes_follow_ups - #{period}"] }).to eq [0, 0, 0, 1, 0, 1]
        expect(periods.map { |period| rows[0]["bs_below_200_rates - #{period}"] }).to eq %w[0% 0% 0% 0% 0% 0%]
        expect(periods.map { |period| rows[0]["bs_200_to_300_rates - #{period}"] }).to eq %w[0% 0% 0% 0% 0% 0%]
        expect(periods.map { |period| rows[0]["bs_over_300_rates - #{period}"] }).to eq %w[0% 0% 0% 0% 0% 0%]

        expect(rows[1]["Blocks"]).to eq "Block 2 - alphabetically second"
        expect(rows[1]["Total diabetes registrations"]).to eq 3
        expect(rows[1]["Total assigned diabetes patients"]).to eq 3
        expect(rows[1]["Total diabetes patients under care"]).to eq 3
        expect(rows[1]["Total diabetes patients lost to followup"]).to eq 0
        expect(rows[1]["% Blood sugar below 200"]).to eq "33%"
        expect(rows[1]["% Blood sugar between 200 and 300"]).to eq "0%"
        expect(rows[1]["% Blood sugar over 300"]).to eq "0%"
        expect(rows[1]["% Diabetes missed Visits"]).to eq "0%"
        expect(rows[1]["% Visits, no blood sugar taken"]).to eq "67%"
        expect(periods.map { |period| rows[1]["cumulative_diabetes_registrations - #{period}"] }).to eq [0, 2, 3, 3, 3, 3]
        expect(periods.map { |period| rows[1]["diabetes_under_care - #{period}"] }).to eq [0, 2, 3, 3, 3, 3]
        expect(periods.map { |period| rows[1]["bs_below_200_rates - #{period}"] }).to eq %w[0% 0% 0% 0% 0% 33%]
        expect(periods.map { |period| rows[1]["bs_200_to_300_rates - #{period}"] }).to eq %w[0% 0% 0% 0% 0% 0%]
        expect(periods.map { |period| rows[1]["bs_over_300_rates - #{period}"] }).to eq %w[0% 0% 0% 0% 0% 0%]
        expect(periods.map { |period| rows[1]["monthly_diabetes_registrations - #{period}"] }).to eq [0, 2, 1, 0, 0, 0]
        expect(periods.map { |period| rows[1]["diabetes_follow_ups - #{period}"] }).to eq [0, 0, 0, 1, 1, 2]
      end
    end

    it "orders the rows by block names" do
      month = Period.month("2021-09-01".to_date)
      region = setup_district_data[:region]
      rows = described_class.new(region, month).content_rows

      expect(rows.map { |row| row["Blocks"] }).to match_array ["Block 1 - alphabetically first", "Block 2 - alphabetically second"]
    end
  end
end
