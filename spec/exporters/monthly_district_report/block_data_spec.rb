require "rails_helper"

def mock_block_repo(repo, district, month)
  periods = Range.new(month.advance(months: -5), month)

  allow(repo).to receive(:cumulative_registrations).and_return({
    district[:block_1].slug => periods.zip([2, 10, 11, 24, 22, 42]).to_h,
    district[:block_2].slug => periods.zip([5, 14, 13, 21, 15, 23]).to_h
  })

  allow(repo).to receive(:cumulative_assigned_patients).and_return({
    district[:block_1].slug => {month => 32},
    district[:block_2].slug => {month => 12}
  })

  allow(repo).to receive(:under_care).and_return({
    district[:block_1].slug => periods.zip([2, 11, 15, 22, 25, 12]).to_h,
    district[:block_2].slug => periods.zip([4, 12, 11, 23, 14, 24]).to_h
  })

  allow(repo).to receive(:ltfu).and_return({
    district[:block_1].slug => {month => 3},
    district[:block_2].slug => {month => 4}
  })

  allow(repo).to receive(:controlled_rates).and_return({
    district[:block_1].slug => periods.zip([2, 10, 21, 24, 22, 40]).to_h,
    district[:block_2].slug => periods.zip([5, 14, 13, 21, 15, 35]).to_h
  })

  allow(repo).to receive(:uncontrolled_rates).and_return({
    district[:block_1].slug => {month => 20},
    district[:block_2].slug => {month => 15}
  })

  allow(repo).to receive(:missed_visits_rate).and_return({
    district[:block_1].slug => {month => 30},
    district[:block_2].slug => {month => 40}
  })

  allow(repo).to receive(:visited_without_bp_taken_rates).and_return({
    district[:block_1].slug => {month => 10},
    district[:block_2].slug => {month => 10}
  })

  allow(repo).to receive(:monthly_registrations).and_return({
    district[:block_1].slug => periods.zip([23, 23, 42, 53, 1, 51]).to_h,
    district[:block_2].slug => periods.zip([12, 98, 11, 77, 12, 11]).to_h
  })

  allow(repo).to receive(:hypertension_follow_ups).and_return({
    district[:block_1].slug => periods.zip([5, 12, 21, 21, 41, 11]).to_h,
    district[:block_2].slug => periods.zip([3, 11, 14, 72, 12, 18]).to_h
  })
end

describe MonthlyDistrictReport::BlockData do
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
      district = setup_district_with_facilities
      month = Period.month("2021-09-01".to_date)
      periods = Range.new(month.advance(months: -5), month)

      repo_double = instance_double(Reports::Repository)
      mock_block_repo(repo_double, district, month)
      allow(Reports::Repository).to receive(:new).and_return(repo_double)
      rows = described_class.new(district[:region], month).content_rows

      expect(rows[0].count).to eq 39

      expect(rows[0]["Blocks"]).to eq "Test Block 1"
      expect(rows[0]["Total registrations"]).to eq 42
      expect(rows[0]["Total assigned patients"]).to eq 32
      expect(rows[0]["Total patients under care"]).to eq 12
      expect(rows[0]["Total patients lost to followup"]).to eq 3
      expect(rows[0]["% BP controlled"]).to eq "40%"
      expect(rows[0]["% BP uncontrolled"]).to eq "20%"
      expect(rows[0]["% Missed Visits"]).to eq "30%"
      expect(rows[0]["% Visits, no BP taken"]).to eq "10%"

      expect(periods.map { |period| rows[0]["cumulative_registrations - #{period}"] }).to eq [2, 10, 11, 24, 22, 42]
      expect(periods.map { |period| rows[0]["under_care - #{period}"] }).to eq [2, 11, 15, 22, 25, 12]
      expect(periods.map { |period| rows[0]["monthly_registrations - #{period}"] }).to eq [23, 23, 42, 53, 1, 51]
      expect(periods.map { |period| rows[0]["hypertension_follow_ups - #{period}"] }).to eq [5, 12, 21, 21, 41, 11]
      expect(periods.map { |period| rows[0]["controlled_rates - #{period}"] }).to eq %w[2% 10% 21% 24% 22% 40%]

      expect(rows[1]["Blocks"]).to eq "Test Block 2"
      expect(rows[1]["Total registrations"]).to eq 23
      expect(rows[1]["Total assigned patients"]).to eq 12
      expect(rows[1]["Total patients under care"]).to eq 24
      expect(rows[1]["Total patients lost to followup"]).to eq 4
      expect(rows[1]["% BP controlled"]).to eq "35%"
      expect(rows[1]["% BP uncontrolled"]).to eq "15%"
      expect(rows[1]["% Missed Visits"]).to eq "40%"
      expect(rows[1]["% Visits, no BP taken"]).to eq "10%"
      expect(periods.map { |period| rows[1]["cumulative_registrations - #{period}"] }).to eq [5, 14, 13, 21, 15, 23]
      expect(periods.map { |period| rows[1]["under_care - #{period}"] }).to eq [4, 12, 11, 23, 14, 24]
      expect(periods.map { |period| rows[1]["controlled_rates - #{period}"] }).to eq %w[5% 14% 13% 21% 15% 35%]
      expect(periods.map { |period| rows[1]["monthly_registrations - #{period}"] }).to eq [12, 98, 11, 77, 12, 11]
      expect(periods.map { |period| rows[1]["hypertension_follow_ups - #{period}"] }).to eq [3, 11, 14, 72, 12, 18]
    end

    it "orders the rows by block names" do
      district = setup_district_with_facilities
      month = Period.month("2021-09-01".to_date)
      rows = described_class.new(district[:region], month).content_rows
      expect(rows.map { |row| row["Blocks"] }).to match_array ["Test Block 1", "Test Block 2"]
    end
  end
end
