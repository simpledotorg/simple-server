require "rails_helper"

describe MonthlyDistrictReport::Diabetes::DistrictData do
  def setup_district_data
    puts "In diabetes", self.class
    organization = FactoryBot.create(:organization)
    facility_group = create(:facility_group, name: "Test District", organization: organization)
    facility1 = create(:facility, name: "Facility 1", block: "Block 1 - alphabetically first", facility_group: facility_group, facility_size: "community", enable_diabetes_management: true)
    facility2 = create(:facility, name: "Facility 2", block: "Block 2 - alphabetically second", facility_group: facility_group, facility_size: "small", enable_diabetes_management: true)
    patient1 = create(:patient, :diabetes, recorded_at: 3.months.ago, assigned_facility: facility1, registration_facility: facility1)
    puts(patient1)
    follow_up_patient = create(:patient, :diabetes, recorded_at: 3.months.ago, assigned_facility: facility2, registration_facility: facility2)
    create(:appointment, creation_facility: facility2, scheduled_date: 2.month.ago, patient: follow_up_patient)
    create(:blood_sugar_with_encounter, :bs_below_200, facility: facility2, patient: follow_up_patient, recorded_at: 2.months.ago)
    puts(follow_up_patient)

    create(:patient, :without_diabetes, recorded_at: 2.months.ago, assigned_facility: facility1, registration_facility: facility1)

    patient2 = create(:patient, :diabetes, recorded_at: 2.years.ago, assigned_facility: facility1, registration_facility: facility1)
    puts(patient2)
    # medications_dispensed_patients
    create(:appointment, facility: facility1, scheduled_date: 10.days.from_now, device_created_at: Date.today, patient: create(:patient, :diabetes, recorded_at: 4.months.ago, registration_facility: facility1))
    create(:appointment, facility: facility2, scheduled_date: 10.days.from_now, device_created_at: Date.today, patient: create(:patient, :diabetes, recorded_at: 4.months.ago, registration_facility: facility2))
    create(:appointment, facility: facility2, scheduled_date: Date.today, device_created_at: 32.days.ago, patient: create(:patient, :diabetes, recorded_at: 4.months.ago, registration_facility: facility2))
    create(:appointment, facility: facility1, scheduled_date: Date.today, device_created_at: 63.days.ago, patient: create(:patient, :diabetes, recorded_at: 4.months.ago, registration_facility: facility1))

    RefreshReportingViews.refresh_v2

    {region: facility_group.region,
     facility_1: facility1,
     facility_2: facility2}
  end

  context "#header_rows" do
    it "returns a list of header rows with the correct number of columns" do
      district = setup_district_with_facilities
      month = Period.month("2021-09-01".to_date)
      header_rows = described_class.new(district[:region], month).header_rows
      expect(header_rows[0].count).to eq 101
      expect(header_rows[1].count).to eq 101
    end
  end

  context "#content_rows" do
    it "returns a hash with the required keys and values" do
      district_data = setup_district_data
      facility_1 = district_data[:facility_1]
      create(:facility, name: "Test Facility 3", facility_group: district_data[:region].source, facility_size: "medium", zone: "Test Block 3", enable_diabetes_management: true)
      create(:facility, name: "Test Facility 4", facility_group: district_data[:region].source, facility_size: "large", zone: "Test Block 4", enable_diabetes_management: true)
      month = Period.current
      periods = Range.new(month.advance(months: -5), month)
      user = create(:user, registration_facility: facility_1)

      periods.each do |period|
        district_data[:region].facilities.each do |facility|
          puts Patient.with_diabetes.count
          create(:patient, :diabetes, registration_facility: facility, registration_user: user, recorded_at: period.value)
          patient = Patient.where(registration_facility: facility).order(:recorded_at).first
          if patient
            create(:blood_sugar, patient: patient, facility: facility, user: user, recorded_at: period.value)
          end
        end
      end

      RefreshReportingViews.refresh_v2

      rows = described_class.new(district_data[:region], month).content_rows
      expect(rows[0].count).to eq 101

      expect(rows[0]["District"]).to eq "Test District"
      expect(rows[0]["Facilities implementing IHCI"]).to eq 4
      expect(rows[0]["Total DHs/SDHs"]).to eq 1
      expect(rows[0]["Total CHCs"]).to eq 1
      expect(rows[0]["Total PHCs"]).to eq 1
      expect(rows[0]["Total HWCs/SCs"]).to eq 1
      expect(periods.map { |period| rows[0]["cumulative_diabetes_registrations - #{period}"] }).to eq [5, 13, 19, 23, 27, 31]
      expect(rows[0]["Total diabetes registrations"]).to eq 31
      expect(rows[0]["Total assigned diabetes patients"]).to eq 31
      expect(rows[0]["Total diabetes patients under care"]).to eq 30
      expect(rows[0]["% Blood sugar below 200"]).to eq "6%"
      expect(rows[0]["% Blood sugar between 200 and 300"]).to eq "0%"
      expect(rows[0]["% Blood sugar over 300"]).to eq "0%"
      expect(rows[0]["% Diabetes missed visits"]).to eq "72%"
      expect(rows[0]["% Visits, no blood sugar taken"]).to eq "22%"

      expect(periods.map { |period| rows[0]["diabetes_under_care - #{period}"] }).to eq [4, 12, 18, 22, 26, 30]
      expect(periods.map { |period| rows[0]["monthly_diabetes_registrations_large_medium - #{period}"] }).to eq [2, 2, 2, 2, 2, 2]
      expect(periods.map { |period| rows[0]["monthly_diabetes_registrations_small - #{period}"] }).to eq [1, 3, 2, 1, 1, 1]
      expect(periods.map { |period| rows[0]["monthly_diabetes_registrations_community - #{period}"] }).to eq [1, 3, 2, 1, 1, 1]
      expect(periods.map { |period| rows[0]["diabetes_follow_ups - #{period}"] }).to eq [1, 4, 4, 6, 5, 7]
      expect(periods.map { |period| rows[0]["bs_below_200_rates - #{period}"] }).to eq %w[0% 0% 0% 0% 0% 6%]
      expect(periods.map { |period| rows[0]["bs_below_200_patients - #{period}"] }).to eq [0, 0, 0, 0, 0, 1]
      expect(periods.map { |period| rows[0]["bs_200_to_300_rates - #{period}"] }).to eq %w[0% 0% 0% 0% 0% 0%]
      expect(periods.map { |period| rows[0]["bs_200_to_300_patients - #{period}"] }).to eq [0, 0, 0, 0, 0, 0]
      expect(periods.map { |period| rows[0]["bs_over_300_rates - #{period}"] }).to eq %w[0% 0% 0% 0% 0% 0%]
      expect(periods.map { |period| rows[0]["bs_over_300_patients - #{period}"] }).to eq [0, 0, 0, 0, 0, 0]

      expect(periods.drop(3).map { |period| rows[0]["cumulative_diabetes_registrations_community - #{period}"] }).to eq [8, 9, 10]
      expect(periods.drop(3).map { |period| rows[0]["cumulative_diabetes_under_care_community - #{period}"] }).to eq [7, 8, 9]
      expect(periods.drop(3).map { |period| rows[0]["cumulative_assigned_diabetes_patients_community_percentage - #{period}"] }).to eq %w[35% 33% 32%]
      expect(periods.drop(3).map { |period| rows[0]["monthly_diabetes_follow_ups_community_percentage - #{period}"] }).to eq %w[33% 20% 29%]
      expect(periods.drop(3).map { |period| rows[0]["cumulative_assigned_diabetes_patients_community - #{period}"] }).to eq [8, 9, 10]
    end

    it "only include active facilities" do
      district_data = setup_district_with_facilities
      create(:facility, name: "Test Facility 3", facility_group: district_data[:region].source, facility_size: "medium", zone: "Test Block 3")
      inactive_facility = create(:facility, name: "Test Facility 4", facility_group: district_data[:region].source, facility_size: "large", zone: "Test Block 4")
      month = Period.month("2021-09-01".to_date)
      periods = Range.new(month.advance(months: -5), month)
      user = create(:user, registration_facility: district_data[:facility_1])

      periods.each do |period|
        district_data[:region].facilities.each do |facility|
          unless facility.id == inactive_facility.id
            create(:patient, registration_facility: facility, registration_user: user, recorded_at: period.value)
            patient = Patient.where(registration_facility: facility).order(:recorded_at).first
            if patient
              create(:blood_pressure, patient: patient, facility: facility, user: user, recorded_at: period.value)
            end
          end
        end
      end

      RefreshReportingViews.refresh_v2

      rows = described_class.new(district_data[:region], month).content_rows
      expect(rows[0].count).to eq 101

      expect(rows[0]["District"]).to eq "Test District"
      expect(rows[0]["Facilities implementing IHCI"]).to eq 3
      expect(rows[0]["Total DHs/SDHs"]).to eq 0
      expect(rows[0]["Total CHCs"]).to eq 1
      expect(rows[0]["Total PHCs"]).to eq 1
      expect(rows[0]["Total HWCs/SCs"]).to eq 1
    end
  end
end
