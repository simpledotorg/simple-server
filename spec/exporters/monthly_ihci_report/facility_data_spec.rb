require "rails_helper"

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

def mock_repo(district, month)
  allow_any_instance_of(Reports::Repository).to receive(:cumulative_registrations).and_return({
    district[:facility_1].slug => {month => 42},
    district[:facility_2].slug => {month => 23}
  })

  allow_any_instance_of(Reports::Repository).to receive(:under_care).and_return({
    district[:facility_1].slug => {month => 12},
    district[:facility_2].slug => {month => 24}
  })

  allow_any_instance_of(Reports::Repository).to receive(:monthly_registrations).and_return({
    district[:facility_1].slug => {month => 1},
    district[:facility_2].slug => {month => 2}
  })

  allow_any_instance_of(Reports::Repository).to receive(:controlled_rates).and_return({
    district[:facility_1].slug => {month => 30},
    district[:facility_2].slug => {month => 40}
  })
end

describe MonthlyIHCIReport::FacilityData do
  around(:example) do |example|
    previous_locale = I18n.locale
    I18n.locale = :en_IN
    example.run
    I18n.locale = previous_locale
  end

  context "#rows" do
    it "returns a hash with the required keys and values" do
      district = setup_district
      month = Period.month("2021-09-01".to_date)

      mock_repo(district, month)

      rows = described_class.new(district[:region], month).rows

      expect(rows[0].count).to eq 8

      expect(rows[0]["Sl.No"]).to eq 1
      expect(rows[0]["Facility size"]).to eq "HWC/SC"
      expect(rows[0]["Name of facility"]).to eq "Test Export Facility 1"
      expect(rows[0]["Name of block"]).to eq "Test Export Block 1"
      expect(rows[0]["Total registrations"]).to eq 42
      expect(rows[0]["Patients under care"]).to eq 12
      expect(rows[0]["Registrations this month"]).to eq 1
      expect(rows[0]["BP control % of all patients registered before 3 months"]).to eq 30

      expect(rows[1]["Sl.No"]).to eq 2
      expect(rows[1]["Facility size"]).to eq "PHC"
      expect(rows[1]["Name of facility"]).to eq "Test Export Facility 2"
      expect(rows[1]["Name of block"]).to eq "Test Export Block 2"
      expect(rows[1]["Total registrations"]).to eq 23
      expect(rows[1]["Patients under care"]).to eq 24
      expect(rows[1]["Registrations this month"]).to eq 2
      expect(rows[1]["BP control % of all patients registered before 3 months"]).to eq 40
    end

    it "orders the rows by block, and then facility names" do
      district = setup_district
      month = Period.month("2021-09-01".to_date)
      rows = described_class.new(district[:region], month).rows
      expect(rows.map { |row| row["Name of facility"] }).to match_array ["Test Export Facility 1", "Test Export Facility 2"]
    end
  end
end
