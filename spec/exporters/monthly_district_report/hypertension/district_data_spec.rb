require "rails_helper"

describe MonthlyDistrictReport::Hypertension::DistrictData do
  def setup_district_data
    organization = FactoryBot.create(:organization)
    facility_group = create(:facility_group, name: "Test District", organization: organization)
    facility1 = create(:facility, name: "Facility 1", block: "Block 1 - alphabetically first", facility_group: facility_group, facility_size: "community")
    facility2 = create(:facility, name: "Facility 2", block: "Block 2 - alphabetically second", facility_group: facility_group, facility_size: "small")
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

    {region: facility_group.region,
     facility_1: facility1,
     facility_2: facility2}
  end

  context "#header_rows" do
    it "returns a list of header rows with the correct number of columns" do
      district = setup_district_with_facilities
      month = Period.month("2021-09-01".to_date)
      header_rows = described_class.new(district[:region], month).header_rows
      expect(header_rows[0].count).to eq 76
      expect(header_rows[1].count).to eq 76
    end
  end

  context "#content_rows", skip: true do
    it "returns a hash with the required keys and values" do
      Timecop.freeze("2022-07-31") do
        district_data = setup_district_data
        create(:facility, name: "Test Facility 3", facility_group: district_data[:region].source, facility_size: "medium", zone: "Test Block 3")
        create(:facility, name: "Test Facility 4", facility_group: district_data[:region].source, facility_size: "large", zone: "Test Block 4")
        today = Date.today
        month = Period.month(today)
        periods = Range.new(month.advance(months: -5), month)
        user = create(:user, registration_facility: district_data[:facility_1])

        periods.each do |period|
          district_data[:region].facilities.each do |facility|
            create(:patient, registration_facility: facility, registration_user: user, recorded_at: period.value)
            patient = Patient.where(registration_facility: facility).order(:recorded_at).first
            if patient
              create(:blood_pressure, patient: patient, facility: facility, user: user, recorded_at: period.value)
            end
          end
        end

        RefreshReportingViews.refresh_v2

        rows = described_class.new(district_data[:region], month).content_rows
        expect(rows[0].count).to eq 76

        expect(rows[0]["District"]).to eq "Test District"
        expect(rows[0]["Facilities implementing IHCI"]).to eq 4
        expect(rows[0]["Total DHs/SDHs"]).to eq 1
        expect(rows[0]["Total CHCs"]).to eq 1
        expect(rows[0]["Total PHCs"]).to eq 1
        expect(rows[0]["Total HWCs/SCs"]).to eq 1
        expect(rows[0]["Total hypertension registrations"]).to eq 31
        expect(rows[0]["Total assigned hypertension patients"]).to eq 31
        expect(rows[0]["Total hypertension patients under care"]).to eq 30
        expect(rows[0]["% BP controlled"]).to eq "6%"
        expect(rows[0]["% BP uncontrolled"]).to eq "0%"
        expect(rows[0]["% Missed Visits"]).to eq "72%"
        expect(rows[0]["% Visits, no BP taken"]).to eq "22%"

        expect(periods.map { |period| rows[0]["cumulative_registrations - #{period}"] }).to eq [5, 13, 19, 23, 27, 31]
        expect(periods.map { |period| rows[0]["under_care - #{period}"] }).to eq [4, 12, 18, 22, 26, 30]
        expect(periods.map { |period| rows[0]["monthly_registrations_large_medium - #{period}"] }).to eq [2, 2, 2, 2, 2, 2]
        expect(periods.map { |period| rows[0]["monthly_registrations_small - #{period}"] }).to eq [1, 3, 2, 1, 1, 1]
        expect(periods.map { |period| rows[0]["monthly_registrations_community - #{period}"] }).to eq [1, 3, 2, 1, 1, 1]
        expect(periods.map { |period| rows[0]["hypertension_follow_ups - #{period}"] }).to eq [1, 4, 4, 6, 5, 7]
        expect(periods.map { |period| rows[0]["controlled_rates - #{period}"] }).to eq %w[0% 0% 0% 0% 0% 6%]
        expect(periods.map { |period| rows[0]["controlled - #{period}"] }).to eq [0, 0, 0, 0, 0, 1]

        expect(periods.drop(3).map { |period| rows[0]["cumulative_registrations_community - #{period}"] }).to eq [8, 9, 10]
        expect(periods.drop(3).map { |period| rows[0]["cumulative_under_care_community - #{period}"] }).to eq [7, 8, 9]
        expect(periods.drop(3).map { |period| rows[0]["cumulative_assigned_patients_community_percentage - #{period}"] }).to eq %w[35% 33% 32%]
        expect(periods.drop(3).map { |period| rows[0]["monthly_follow_ups_community_percentage - #{period}"] }).to eq %w[33% 20% 29%]
        expect(periods.drop(3).map { |period| rows[0]["cumulative_assigned_patients_community - #{period}"] }).to eq [8, 9, 10]
      end
    end

    it "only include active facilities" do
      district_data = setup_district_data
      _inactive_facility = create(:facility, name: "Test Facility 4", facility_group: district_data[:region].source, facility_size: "large", zone: "Test Block 4")
      today = Date.today
      month = Period.month(today)
      RefreshReportingViews.refresh_v2

      rows = described_class.new(district_data[:region], month).content_rows

      expect(rows[0].count).to eq 76
      expect(rows[0]["District"]).to eq "Test District"
      expect(rows[0]["Facilities implementing IHCI"]).to eq 2
      expect(rows[0]["Total DHs/SDHs"]).to eq 0
      expect(rows[0]["Total CHCs"]).to eq 0
      expect(rows[0]["Total PHCs"]).to eq 1
      expect(rows[0]["Total HWCs/SCs"]).to eq 1
    end
  end
end
