require "rails_helper"

describe MonthlyDistrictReport::Diabetes::FacilityData do
  around(:example) do |example|
    previous_locale = I18n.locale
    I18n.locale = :en_IN
    example.run
    I18n.locale = previous_locale
  end

  context "#header_rows" do
    it "returns a list of header rows with the correct number of columns" do
      district = setup_district_with_facilities
      month = Period.month("2021-09-01".to_date)
      header_rows = described_class.new(district[:region], month).header_rows
      expect(header_rows[0].count).to eq 10
    end
  end

  context "#content_rows" do
    it "returns a hash with the required keys and values" do
      Timecop.freeze("2022-07-01") do
        district = setup_district_with_facilities
        today = Date.today
        month = Period.month(today)
        # We are creating patients for these facilities so that they are considered as active
        district[:region].facilities.each do |facility|
          facility.update(enable_diabetes_management: true)
          create(:patient, :diabetes, registration_facility: facility, device_created_at: month.to_date)
          patient = create(:patient, :diabetes, registration_facility: facility, recorded_at: 3.months.ago)
          create(:blood_sugar_with_encounter, :bs_over_300, facility: facility, patient: patient)
        end

        refresh_views

        rows = described_class.new(district[:region], month).content_rows

        expect(rows[0].count).to eq 10

        expect(rows[0]["Sl.No"]).to eq 1
        expect(rows[0]["Facility size"]).to eq "HWC/SC"
        expect(rows[0]["Name of facility"]).to eq "Test Facility 1"
        expect(rows[0]["Name of block"]).to eq "Test Block 1"
        expect(rows[0]["Total diabetes registrations"]).to eq 2
        expect(rows[0]["Diabetes patients under care"]).to eq 1
        expect(rows[0]["Diabetes patients registered this month"]).to eq 1
        expect(rows[0]["Blood sugar below 200 % of all patients registered before 3 months"]).to eq "0%"
        expect(rows[0]["Blood sugar between 200 and 300 % of all patients registered before 3 months"]).to eq "0%"
        expect(rows[0]["Blood sugar over 300 % of all patients registered before 3 months"]).to eq "100%"

        expect(rows[1]["Sl.No"]).to eq 2
        expect(rows[1]["Facility size"]).to eq "PHC"
        expect(rows[1]["Name of facility"]).to eq "Test Facility 2"
        expect(rows[1]["Name of block"]).to eq "Test Block 2"
        expect(rows[1]["Total diabetes registrations"]).to eq 2
        expect(rows[1]["Diabetes patients under care"]).to eq 1
        expect(rows[1]["Diabetes patients registered this month"]).to eq 1
        expect(rows[1]["Blood sugar below 200 % of all patients registered before 3 months"]).to eq "0%"
        expect(rows[1]["Blood sugar between 200 and 300 % of all patients registered before 3 months"]).to eq "0%"
        expect(rows[1]["Blood sugar over 300 % of all patients registered before 3 months"]).to eq "100%"
      end
    end

    it "orders the rows by block, and then facility names" do
      district = setup_district_with_facilities
      month = Period.month("2021-09-01".to_date)

      # We are creating patients for these facilities so that they are considered as active
      district[:region].facilities.each do |facility|
        facility.update(enable_diabetes_management: true)
        create(:patient, :diabetes, registration_facility: facility, device_created_at: month.to_date)
      end

      refresh_views

      rows = described_class.new(district[:region], month).content_rows
      expect(rows.map { |row| row["Name of facility"] }).to match_array ["Test Facility 1", "Test Facility 2"]
    end

    it "only includes active facilities" do
      district = setup_district_with_facilities
      month = Period.month("2021-09-01".to_date)

      # We are creating patients for these facilities so that they are considered as active
      district[:facility_1].update(enable_diabetes_management: true)
      create(:patient, :diabetes, registration_facility: district[:facility_1], device_created_at: month.to_date)

      refresh_views

      rows = described_class.new(district[:region], month).content_rows
      expect(rows.count).to eq(1)
      expect(rows.map { |row| row["Name of facility"] }).to include("Test Facility 1")
      expect(rows.map { |row| row["Name of facility"] }).not_to include("Test Facility 2")
    end
  end
end
