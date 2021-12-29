require "rails_helper"

def periods(report_month)
  Range.new(report_month.advance(months: -5), report_month)
end

def setup_district
  facility_group = create(:facility_group, name: "Test Export District")
  {
    region: facility_group.region,
    block_1: create(:region, :block, name: "Test Export Block 1", reparent_to: facility_group.region),
    block_2: create(:region, :block, name: "Test Export Block 2", reparent_to: facility_group.region),
    facility_1: create(:facility, name: "Test Export Facility 1", facility_group: facility_group, facility_size: "community", zone: "Test Export Block 1"),
    facility_2: create(:facility, name: "Test Export Facility 2", facility_group: facility_group, facility_size: "small", zone: "Test Export Block 2")
  }
end

def mock_repo(repo, district, month)
  allow(repo).to receive(:cumulative_registrations).and_return({
    district[:block_1].slug => periods(month).zip([2, 10, 11, 24, 22, 42]).to_h,
    district[:block_2].slug => periods(month).zip([5, 14, 13, 21, 15, 23]).to_h
  })

  allow(repo).to receive(:cumulative_assigned_patients).and_return({
    district[:block_1].slug => {month => 32},
    district[:block_2].slug => {month => 12}
  })

  allow(repo).to receive(:under_care).and_return({
    district[:block_1].slug => periods(month).zip([2, 11, 15, 22, 25, 12]).to_h,
    district[:block_2].slug => periods(month).zip([4, 12, 11, 23, 14, 24]).to_h
  })

  allow(repo).to receive(:ltfu).and_return({
    district[:block_1].slug => {month => 3},
    district[:block_2].slug => {month => 4}
  })

  allow(repo).to receive(:controlled_rates).and_return({
    district[:block_1].slug => periods(month).zip([2, 10, 21, 24, 22, 40]).to_h,
    district[:block_2].slug => periods(month).zip([5, 14, 13, 21, 15, 35]).to_h
  })

  allow(repo).to receive(:controlled).and_return({
    district[:block_1].slug => periods(month).zip([20, 100, 210, 240, 220, 400]).to_h,
    district[:block_2].slug => periods(month).zip([50, 140, 130, 210, 150, 350]).to_h
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
    district[:block_1].slug => periods(month).zip([23, 23, 42, 53, 1, 51]).to_h,
    district[:block_2].slug => periods(month).zip([12, 98, 11, 77, 12, 11]).to_h
  })

  allow(repo).to receive(:hypertension_follow_ups).and_return({
    district[:block_1].slug => periods(month).zip([5, 12, 21, 21, 41, 11]).to_h,
    district[:block_2].slug => periods(month).zip([3, 11, 14, 72, 12, 18]).to_h
  })
end

describe MonthlyDistrictReport::DistrictData do
  context "#header_rows" do
    it "returns a list of header rows with the correct number of columns" do
      district = setup_district
      month = Period.month("2021-09-01".to_date)
      header_rows = described_class.new(district[:region], month).header_rows
      expect(header_rows[0].count).to eq 76
      expect(header_rows[1].count).to eq 76
    end
  end

  context "#content_rows" do
    it "returns a hash with the required keys and values" do
      district = setup_district
      month = Period.month("2021-09-01".to_date)

      repo_double = instance_double(Reports::Repository)
      mock_repo(repo_double, district, month)
      allow(Reports::Repository).to receive(:new).and_return(repo_double)

      rows = described_class.new(district[:region], month).content_rows
      expect(rows[0].count).to eq 76
    end
  end
end
