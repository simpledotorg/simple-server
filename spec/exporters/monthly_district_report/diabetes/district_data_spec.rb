require "rails_helper"

def mock_district_repo(repo, district, month)
  periods = Range.new(month.advance(months: -5), month)

  allow(repo).to receive(:cumulative_diabetes_registrations).and_return({
    district[:region].slug => periods.zip([5, 14, 13, 21, 15, 23]).to_h
  })

  allow(repo).to receive(:cumulative_assigned_diabetic_patients).and_return({
    district[:region].slug => periods.zip([7, 8, 9, 10, 11, 12]).to_h
  })

  allow(repo).to receive(:diabetes_under_care).and_return({
    district[:region].slug => periods.zip([4, 12, 11, 23, 14, 24]).to_h
  })

  allow(repo).to receive(:diabetes_ltfu).and_return({
    district[:region].slug => {month => 4}
  })

  allow(repo).to receive(:bs_below_200_rates).and_return({
    district[:region].slug => periods.zip([5, 14, 13, 15, 35, 21]).to_h
  })

  allow(repo).to receive(:bs_below_200_patients).and_return({
    district[:region].slug => periods.zip([50, 140, 130, 150, 350, 210]).to_h
  })

  allow(repo).to receive(:bs_200_to_300_rates).and_return({
    district[:region].slug => periods.zip([2, 10, 21, 24, 22, 40]).to_h
  })

  allow(repo).to receive(:bs_200_to_300_patients).and_return({
    district[:region].slug => periods.zip([20, 100, 210, 240, 220, 400]).to_h
  })

  allow(repo).to receive(:bs_over_300_rates).and_return({
    district[:region].slug => periods.zip([3, 15, 12, 34, 26, 10]).to_h
  })

  allow(repo).to receive(:bs_over_300_patients).and_return({
    district[:region].slug => periods.zip([30, 150, 120, 340, 260, 100]).to_h
  })

  allow(repo).to receive(:diabetes_missed_visits_rates).and_return({
    district[:region].slug => {month => 40}
  })

  allow(repo).to receive(:visited_without_bs_taken_rates).and_return({
    district[:region].slug => {month => 10}
  })

  allow(repo).to receive(:monthly_diabetes_registrations).and_return({
    district[:region].slug => periods.zip([12, 98, 11, 77, 12, 11]).to_h
  })

  allow(repo).to receive(:diabetes_follow_ups).and_return({
    district[:region].slug => periods.zip([3, 11, 14, 72, 12, 18]).to_h
  })
end

describe MonthlyDistrictReport::Diabetes::DistrictData do
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
      district = setup_district_with_facilities
      create(:facility, name: "Test Facility 3", facility_group: district[:region].source, facility_size: "medium", zone: "Test Block 3")
      create(:facility, name: "Test Facility 4", facility_group: district[:region].source, facility_size: "large", zone: "Test Block 4")
      month = Period.month("2021-09-01".to_date)
      periods = Range.new(month.advance(months: -5), month)
      user = create(:user, registration_facility: district[:facility_1])

      repo_double = instance_double(Reports::Repository)
      mock_district_repo(repo_double, district, month)
      allow(Reports::Repository).to receive(:new).and_return(repo_double)

      periods.each do |period|
        district[:region].facilities.each do |facility|
          create(:patient, registration_facility: facility, registration_user: user, recorded_at: period.value)
          patient = Patient.where(registration_facility: facility).order(:recorded_at).first
          if patient
            create(:blood_pressure, patient: patient, facility: facility, user: user, recorded_at: period.value)
          end
        end
      end

      RefreshReportingViews.refresh_v2

      rows = described_class.new(district[:region], month).content_rows
      expect(rows[0].count).to eq 101

      expect(rows[0]["District"]).to eq "Test District"
      expect(rows[0]["Facilities implementing IHCI"]).to eq 4
      expect(rows[0]["Total DHs/SDHs"]).to eq 1
      expect(rows[0]["Total CHCs"]).to eq 1
      expect(rows[0]["Total PHCs"]).to eq 1
      expect(rows[0]["Total HWCs/SCs"]).to eq 1
      expect(rows[0]["Total diabetes registrations"]).to eq 23
      expect(rows[0]["Total assigned diabetes patients"]).to eq 12
      expect(rows[0]["Total diabetes patients under care"]).to eq 24
      expect(rows[0]["% Blood sugar below 200"]).to eq "21%"
      expect(rows[0]["% Blood sugar between 200 and 300"]).to eq "40%"
      expect(rows[0]["% Blood sugar over 300"]).to eq "10%"
      expect(rows[0]["% Diabetes missed visits"]).to eq "40%"
      expect(rows[0]["% Visits, no blood sugar taken"]).to eq "10%"

      expect(periods.map { |period| rows[0]["cumulative_diabetes_registrations - #{period}"] }).to eq [5, 14, 13, 21, 15, 23]
      expect(periods.map { |period| rows[0]["diabetes_under_care - #{period}"] }).to eq [4, 12, 11, 23, 14, 24]
      expect(periods.map { |period| rows[0]["monthly_diabetes_registrations_large_medium - #{period}"] }).to eq [2, 2, 2, 2, 2, 2]
      expect(periods.map { |period| rows[0]["monthly_diabetes_registrations_small - #{period}"] }).to eq [1, 1, 1, 1, 1, 1]
      expect(periods.map { |period| rows[0]["monthly_diabetes_registrations_community - #{period}"] }).to eq [1, 1, 1, 1, 1, 1]
      expect(periods.map { |period| rows[0]["diabetes_follow_ups - #{period}"] }).to eq [3, 11, 14, 72, 12, 18]
      expect(periods.map { |period| rows[0]["bs_below_200_rates - #{period}"] }).to eq %w[5% 14% 13% 15% 35% 21%]
      expect(periods.map { |period| rows[0]["bs_below_200_patients - #{period}"] }).to eq [50, 140, 130, 150, 350, 210]
      expect(periods.map { |period| rows[0]["bs_200_to_300_rates - #{period}"] }).to eq %w[2% 10% 21% 24% 22% 40%]
      expect(periods.map { |period| rows[0]["bs_200_to_300_patients - #{period}"] }).to eq [20, 100, 210, 240, 220, 400]
      expect(periods.map { |period| rows[0]["bs_over_300_rates - #{period}"] }).to eq %w[3% 15% 12% 34% 26% 10%]
      expect(periods.map { |period| rows[0]["bs_over_300_patients - #{period}"] }).to eq [30, 150, 120, 340, 260, 100]

      expect(periods.drop(3).map { |period| rows[0]["cumulative_diabetes_registrations_community - #{period}"] }).to eq [4, 5, 6]
      expect(periods.drop(3).map { |period| rows[0]["cumulative_diabetes_under_care_community - #{period}"] }).to eq [4, 5, 6]
      expect(periods.drop(3).map { |period| rows[0]["cumulative_assigned_diabetes_patients_community_percentage - #{period}"] }).to eq %w[40% 45% 50%]
      expect(periods.drop(3).map { |period| rows[0]["monthly_diabetes_follow_ups_community_percentage - #{period}"] }).to eq %w[25% 25% 25%]
      expect(periods.drop(3).map { |period| rows[0]["cumulative_assigned_diabetic_patients_community - #{period}"] }).to eq [4, 5, 6]
    end

    it "only include active facilities" do
      district = setup_district_with_facilities
      create(:facility, name: "Test Facility 3", facility_group: district[:region].source, facility_size: "medium", zone: "Test Block 3")
      inactive_facility = create(:facility, name: "Test Facility 4", facility_group: district[:region].source, facility_size: "large", zone: "Test Block 4")
      month = Period.month("2021-09-01".to_date)
      periods = Range.new(month.advance(months: -5), month)
      user = create(:user, registration_facility: district[:facility_1])

      repo_double = instance_double(Reports::Repository)
      mock_district_repo(repo_double, district, month)
      allow(Reports::Repository).to receive(:new).and_return(repo_double)

      periods.each do |period|
        district[:region].facilities.each do |facility|
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

      rows = described_class.new(district[:region], month).content_rows
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
