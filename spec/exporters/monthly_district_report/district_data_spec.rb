require "rails_helper"

def mock_district_repo(repo, district, month)
  periods = Range.new(month.advance(months: -5), month)

  allow(repo).to receive(:cumulative_registrations).and_return({
    district[:region].slug => periods.zip([5, 14, 13, 21, 15, 23]).to_h
  })

  allow(repo).to receive(:cumulative_assigned_patients).and_return({
    district[:region].slug => periods.zip([7, 8, 9, 10, 11, 12]).to_h
  })

  allow(repo).to receive(:under_care).and_return({
    district[:region].slug => periods.zip([4, 12, 11, 23, 14, 24]).to_h
  })

  allow(repo).to receive(:ltfu).and_return({
    district[:region].slug => {month => 4}
  })

  allow(repo).to receive(:controlled_rates).and_return({
    district[:region].slug => periods.zip([5, 14, 13, 21, 15, 35]).to_h
  })

  allow(repo).to receive(:controlled).and_return({
    district[:region].slug => periods.zip([50, 140, 130, 210, 150, 350]).to_h
  })

  allow(repo).to receive(:uncontrolled_rates).and_return({
    district[:region].slug => {month => 15}
  })

  allow(repo).to receive(:missed_visits_rate).and_return({
    district[:region].slug => {month => 40}
  })

  allow(repo).to receive(:visited_without_bp_taken_rates).and_return({
    district[:region].slug => {month => 10}
  })

  allow(repo).to receive(:monthly_registrations).and_return({
    district[:region].slug => periods.zip([12, 98, 11, 77, 12, 11]).to_h
  })

  allow(repo).to receive(:hypertension_follow_ups).and_return({
    district[:region].slug => periods.zip([3, 11, 14, 72, 12, 18]).to_h
  })
end

describe MonthlyDistrictReport::DistrictData do
  context "#header_rows" do
    it "returns a list of header rows with the correct number of columns" do
      district = setup_district_with_facilities
      month = Period.month("2021-09-01".to_date)
      header_rows = described_class.new(district[:region], month).header_rows
      expect(header_rows[0].count).to eq 76
      expect(header_rows[1].count).to eq 76
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

      RefreshReportingViews.new.refresh_v2

      rows = described_class.new(district[:region], month).content_rows
      expect(rows[0].count).to eq 76

      expect(rows[0]["District"]).to eq "Test District"
      expect(rows[0]["Facilities implementing IHCI"]).to eq 4
      expect(rows[0]["Total DHs/SDHs"]).to eq 1
      expect(rows[0]["Total CHCs"]).to eq 1
      expect(rows[0]["Total PHCs"]).to eq 1
      expect(rows[0]["Total HWCs/SCs"]).to eq 1
      expect(rows[0]["Total registrations"]).to eq 23
      expect(rows[0]["Total assigned patients"]).to eq 12
      expect(rows[0]["Total patients under care"]).to eq 24
      expect(rows[0]["% BP controlled"]).to eq "35%"
      expect(rows[0]["% BP uncontrolled"]).to eq "15%"
      expect(rows[0]["% Missed Visits"]).to eq "40%"
      expect(rows[0]["% Visits, no BP taken"]).to eq "10%"

      expect(periods.map { |period| rows[0]["cumulative_registrations - #{period}"] }).to eq [5, 14, 13, 21, 15, 23]
      expect(periods.map { |period| rows[0]["under_care - #{period}"] }).to eq [4, 12, 11, 23, 14, 24]
      expect(periods.map { |period| rows[0]["monthly_registrations_large_medium - #{period}"] }).to eq [2, 2, 2, 2, 2, 2]
      expect(periods.map { |period| rows[0]["monthly_registrations_small - #{period}"] }).to eq [1, 1, 1, 1, 1, 1]
      expect(periods.map { |period| rows[0]["monthly_registrations_community - #{period}"] }).to eq [1, 1, 1, 1, 1, 1]
      expect(periods.map { |period| rows[0]["hypertension_follow_ups - #{period}"] }).to eq [3, 11, 14, 72, 12, 18]
      expect(periods.map { |period| rows[0]["controlled_rates - #{period}"] }).to eq %w[5% 14% 13% 21% 15% 35%]
      expect(periods.map { |period| rows[0]["controlled - #{period}"] }).to eq [50, 140, 130, 210, 150, 350]

      expect(periods.drop(3).map { |period| rows[0]["cumulative_registrations_community - #{period}"] }).to eq [4, 5, 6]
      expect(periods.drop(3).map { |period| rows[0]["cumulative_under_care_community - #{period}"] }).to eq [4, 5, 6]
      expect(periods.drop(3).map { |period| rows[0]["cumulative_assigned_patients_community_percentage - #{period}"] }).to eq %w[40% 45% 50%]
      expect(periods.drop(3).map { |period| rows[0]["monthly_follow_ups_community_percentage - #{period}"] }).to eq %w[25% 25% 25%]
      expect(periods.drop(3).map { |period| rows[0]["cumulative_assigned_patients_community - #{period}"] }).to eq [4, 5, 6]
    end
  end
end
