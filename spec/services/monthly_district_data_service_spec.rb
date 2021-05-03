require "rails_helper"

RSpec.describe MonthlyDistrictDataService do
  let(:organization) { FactoryBot.create(:organization) }
  let(:facility_group) { create(:facility_group, organization: organization) }
  let(:facility) { create(:facility, facility_group: facility_group) }
  let(:region) { facility.region.district_region }
  let(:hypertensive_patient) { create(:patient, :hypertension, assigned_facility: facility) }
  let(:period) { Period.month(Date.today) }
  let(:service) { described_class.new(region, period) }

  def find_in_csv(csv_data, row_index, column_name)
    headers = csv_data[2]
    column = headers.index(column_name)
    csv_data[row_index][column]
  end

  describe "#report" do
    it "produces valid csv data" do
      result = service.report
      expect {
        CSV.parse(result)
      }.not_to raise_error
    end

    it "provides accurate numbers for the district" do
      hypertensive_patient
      result = service.report
      csv = CSV.parse(result)
      region_row_index = 3
      expect(find_in_csv(csv, region_row_index, "#")).to eq("All")
      expect(find_in_csv(csv, region_row_index, "District")).to eq(region.name)
      expect(csv[region_row_index][2..6].uniq).to eq([nil])
      expect(find_in_csv(csv, region_row_index, "Total registrations")).to eq("0")
      expect(find_in_csv(csv, region_row_index, "Total assigned patients")).to eq("1")
      expect(find_in_csv(csv, region_row_index, "Lost to follow-up patients")).to eq("0")
      expect(find_in_csv(csv, region_row_index, "Died all-time")).to eq("0")
      expect(find_in_csv(csv, region_row_index, "Patients under care")).to eq("1")
      expect(find_in_csv(csv, region_row_index, "Patients with BP controlled")).to eq("0")
      expect(find_in_csv(csv, region_row_index, "Patients with BP not controlled")).to eq("0")
      expect(find_in_csv(csv, region_row_index, "Patients with a missed visits")).to eq("0")
      expect(find_in_csv(csv, region_row_index, "Patients with a visit but no BP taken")).to eq("0")
      expect(csv[region_row_index][30..31].uniq).to eq([nil])
    end

    it "provides accurate numbers for the facilities" do
      hypertensive_patient
      result = service.report
      csv = CSV.parse(result)
      facility_row_index = 4
      expect(find_in_csv(csv, facility_row_index, "#")).to eq("1")
      expect(find_in_csv(csv, facility_row_index, "District")).to eq(region.name)
      expect(find_in_csv(csv, facility_row_index, "Facility")).to eq(facility.name)
      expect(find_in_csv(csv, facility_row_index, "Block")).to eq(facility.block)
      expect(find_in_csv(csv, facility_row_index, "Active/Inactive (Inactive facilities have 0 BP measures taken)"))
        .to eq("Inactive")
      expect(find_in_csv(csv, facility_row_index, "Estimated hypertensive population")).to eq(nil)
      expect(find_in_csv(csv, facility_row_index, "Total registrations")).to eq("0")
      expect(find_in_csv(csv, facility_row_index, "Total assigned patients")).to eq("1")
      expect(find_in_csv(csv, facility_row_index, "Lost to follow-up patients")).to eq("0")
      expect(find_in_csv(csv, facility_row_index, "Died all-time")).to eq("0")
      expect(find_in_csv(csv, facility_row_index, "Patients under care")).to eq("1")
      expect(find_in_csv(csv, facility_row_index, "Patients with BP controlled")).to eq("0")
      expect(find_in_csv(csv, facility_row_index, "Patients with BP not controlled")).to eq("0")
      expect(find_in_csv(csv, facility_row_index, "Patients with a missed visits")).to eq("0")
      expect(find_in_csv(csv, facility_row_index, "Patients with a visit but no BP taken")).to eq("0")
      expect(csv[facility_row_index][30..31].uniq).to eq([nil])
    end
  end
end
