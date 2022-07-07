require "rails_helper"

def mock_block_repo(repo, district, month)
  periods = Range.new(month.advance(months: -5), month)

  allow(repo).to receive(:cumulative_diabetes_registrations).and_return({
    district[:block_1].slug => periods.zip([2, 10, 11, 24, 22, 42]).to_h,
    district[:block_2].slug => periods.zip([5, 14, 13, 21, 15, 23]).to_h
  })

  allow(repo).to receive(:cumulative_assigned_diabetic_patients).and_return({
    district[:block_1].slug => {month => 32},
    district[:block_2].slug => {month => 12}
  })

  allow(repo).to receive(:diabetes_under_care).and_return({
    district[:block_1].slug => periods.zip([2, 11, 15, 22, 25, 12]).to_h,
    district[:block_2].slug => periods.zip([4, 12, 11, 23, 14, 24]).to_h
  })

  allow(repo).to receive(:adjusted_diabetes_patients).and_return({
    district[:block_1].slug => periods.zip([2, 11, 15, 22, 25, 12]).to_h,
    district[:block_2].slug => periods.zip([4, 12, 11, 23, 14, 24]).to_h
  })

  allow(repo).to receive(:diabetes_ltfu).and_return({
    district[:block_1].slug => {month => 3},
    district[:block_2].slug => {month => 4}
  })

  allow(repo).to receive(:bs_below_200_rates).and_return({
    district[:block_1].slug => periods.zip([2, 10, 21, 24, 22, 40]).to_h,
    district[:block_2].slug => periods.zip([5, 14, 13, 15, 35, 21]).to_h
  })

  allow(repo).to receive(:bs_200_to_300_rates).and_return({
    district[:block_1].slug => periods.zip([3, 15, 12, 34, 26, 10]).to_h,
    district[:block_2].slug => periods.zip([20, 13, 3, 24, 5, 35]).to_h
  })

  allow(repo).to receive(:bs_over_300_rates).and_return({
    district[:block_1].slug => periods.zip([22, 10, 13, 15, 27, 13]).to_h,
    district[:block_2].slug => periods.zip([21, 5, 14, 15, 35, 13]).to_h
  })

  allow(repo).to receive(:diabetes_missed_visits_rates).and_return({
    district[:block_1].slug => {month => 30},
    district[:block_2].slug => {month => 40}
  })

  allow(repo).to receive(:visited_without_bs_taken_rates).and_return({
    district[:block_1].slug => {month => 10},
    district[:block_2].slug => {month => 10}
  })

  allow(repo).to receive(:monthly_diabetes_registrations).and_return({
    district[:block_1].slug => periods.zip([23, 23, 42, 53, 1, 51]).to_h,
    district[:block_2].slug => periods.zip([12, 98, 11, 77, 12, 11]).to_h
  })

  allow(repo).to receive(:diabetes_follow_ups).and_return({
    district[:block_1].slug => periods.zip([5, 12, 21, 21, 41, 11]).to_h,
    district[:block_2].slug => periods.zip([3, 11, 14, 72, 12, 18]).to_h
  })
end

describe MonthlyDistrictReport::Diabetes::BlockData do
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
      district = setup_district_with_facilities
      month = Period.month("2021-09-01".to_date)
      periods = Range.new(month.advance(months: -5), month)

      repo_double = instance_double(Reports::Repository)
      mock_block_repo(repo_double, district, month)
      allow(Reports::Repository).to receive(:new).and_return(repo_double)
      rows = described_class.new(district[:region], month).content_rows

      expect(rows[0].count).to eq 52

      expect(rows[0]["Blocks"]).to eq "Test Block 1"
      expect(rows[0]["Total diabetes registrations"]).to eq 42
      expect(rows[0]["Total assigned diabetes patients"]).to eq 32
      expect(rows[0]["Total diabetes patients under care"]).to eq 12
      expect(rows[0]["Total diabetes patients lost to followup"]).to eq 3
      expect(rows[0]["% Blood sugar below 200"]).to eq "40%"
      expect(rows[0]["% Blood sugar between 200 and 300"]).to eq "10%"
      expect(rows[0]["% Blood sugar over 300"]).to eq "13%"
      expect(rows[0]["% Diabetes missed Visits"]).to eq "30%"
      expect(rows[0]["% Visits, no blood sugar taken"]).to eq "10%"

      expect(periods.map { |period| rows[0]["cumulative_diabetes_registrations - #{period}"] }).to eq [2, 10, 11, 24, 22, 42]
      expect(periods.map { |period| rows[0]["diabetes_under_care - #{period}"] }).to eq [2, 11, 15, 22, 25, 12]
      expect(periods.map { |period| rows[0]["monthly_diabetes_registrations - #{period}"] }).to eq [23, 23, 42, 53, 1, 51]
      expect(periods.map { |period| rows[0]["diabetes_follow_ups - #{period}"] }).to eq [5, 12, 21, 21, 41, 11]
      expect(periods.map { |period| rows[0]["bs_below_200_rates - #{period}"] }).to eq %w[2% 10% 21% 24% 22% 40%]
      expect(periods.map { |period| rows[0]["bs_200_to_300_rates - #{period}"] }).to eq %w[3% 15% 12% 34% 26% 10%]
      expect(periods.map { |period| rows[0]["bs_over_300_rates - #{period}"] }).to eq %w[22% 10% 13% 15% 27% 13%]

      expect(rows[1]["Blocks"]).to eq "Test Block 2"
      expect(rows[1]["Total diabetes registrations"]).to eq 23
      expect(rows[1]["Total assigned diabetes patients"]).to eq 12
      expect(rows[1]["Total diabetes patients under care"]).to eq 24
      expect(rows[1]["Total diabetes patients lost to followup"]).to eq 4
      expect(rows[1]["% Blood sugar below 200"]).to eq "21%"
      expect(rows[1]["% Blood sugar between 200 and 300"]).to eq "35%"
      expect(rows[1]["% Blood sugar over 300"]).to eq "13%"
      expect(rows[1]["% Diabetes missed Visits"]).to eq "40%"
      expect(rows[1]["% Visits, no blood sugar taken"]).to eq "10%"
      expect(periods.map { |period| rows[1]["cumulative_diabetes_registrations - #{period}"] }).to eq [5, 14, 13, 21, 15, 23]
      expect(periods.map { |period| rows[1]["diabetes_under_care - #{period}"] }).to eq [4, 12, 11, 23, 14, 24]
      expect(periods.map { |period| rows[1]["bs_below_200_rates - #{period}"] }).to eq %w[5% 14% 13% 15% 35% 21%]
      expect(periods.map { |period| rows[1]["bs_200_to_300_rates - #{period}"] }).to eq %w[20% 13% 3% 24% 5% 35%]
      expect(periods.map { |period| rows[1]["bs_over_300_rates - #{period}"] }).to eq %w[21% 5% 14% 15% 35% 13%]
      expect(periods.map { |period| rows[1]["monthly_diabetes_registrations - #{period}"] }).to eq [12, 98, 11, 77, 12, 11]
      expect(periods.map { |period| rows[1]["diabetes_follow_ups - #{period}"] }).to eq [3, 11, 14, 72, 12, 18]
    end

    it "orders the rows by block names" do
      district = setup_district_with_facilities
      month = Period.month("2021-09-01".to_date)
      rows = described_class.new(district[:region], month).content_rows
      expect(rows.map { |row| row["Blocks"] }).to match_array ["Test Block 1", "Test Block 2"]
    end
  end
end
