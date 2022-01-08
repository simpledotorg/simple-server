require "rails_helper"

RSpec.describe MonthlyDistrictDataService do
  let(:organization) { FactoryBot.create(:organization) }
  let(:facility_group) { create(:facility_group, organization: organization) }
  let(:facility1) { create(:facility, facility_group: facility_group, facility_size: :community) }
  let(:facility2) { create(:facility, facility_group: facility_group, facility_size: :community) }
  let(:region) { facility1.region.district_region }
  let(:period) { Period.month(Date.today) }
  let(:service) { described_class.new(region, period) }
  let(:missed_visit_patient) do
    patient = create(:patient, :hypertension, recorded_at: 3.months.ago, assigned_facility: facility1, registration_facility: facility1)
    create(:appointment, creation_facility: facility1, scheduled_date: 2.months.ago, patient: patient)
    patient
  end
  let(:follow_up_patient) do
    patient = create(:patient, :hypertension, recorded_at: 3.months.ago, assigned_facility: facility2, registration_facility: facility2)
    create(:appointment, creation_facility: facility2, scheduled_date: 2.month.ago, patient: patient)
    create(:bp_with_encounter, :under_control, facility: facility2, patient: patient, recorded_at: 2.months.ago)
    patient
  end
  let(:patient_without_hypertension) do
    create(:patient, :without_hypertension, recorded_at: 3.months.ago, assigned_facility: facility1, registration_facility: facility1)
  end
  let(:ltfu_patient) { create(:patient, :hypertension, recorded_at: 2.years.ago, assigned_facility: facility1, registration_facility: facility1) }

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
      missed_visit_patient
      follow_up_patient
      patient_without_hypertension
      ltfu_patient
      RefreshReportingViews.new.refresh_v2

      result = service.report
      csv = CSV.parse(result)
      row_index = 3

      expect(find_in_csv(csv, row_index, "#")).to eq("All facilities")
      expect(csv[row_index][1..3].uniq).to eq([nil])
      expect(find_in_csv(csv, row_index, "Facility size")).to eq("All")
      expect(find_in_csv(csv, row_index, "Estimated hypertensive population")).to eq(nil)
      expect(find_in_csv(csv, row_index, "Total registrations")).to eq("3")
      expect(find_in_csv(csv, row_index, "Total assigned patients")).to eq("3")
      expect(find_in_csv(csv, row_index, "Lost to follow-up patients")).to eq("1")
      dead = find_in_csv(csv, row_index, "Dead patients (All-time as of #{Date.current.strftime("%e-%b-%Y")})")
      expect(dead).to eq("0")
      expect(find_in_csv(csv, row_index, "Patients under care as of #{period.adjusted_period.end.strftime("%e-%b-%Y")}")).to eq("2")
      new_registrations = csv[row_index][11..16]
      expect(new_registrations).to eq(%w[0 0 2 0 0 0])
      follow_ups = csv[row_index][17..22]
      expect(follow_ups).to eq(%w[0 0 0 1 0 0])
      expect(find_in_csv(csv, row_index, "Patients with BP controlled")).to eq("1")
      expect(find_in_csv(csv, row_index, "Patients with BP not controlled")).to eq("0")
      expect(find_in_csv(csv, row_index, "Patients with a missed visit")).to eq("0")
      expect(find_in_csv(csv, row_index, "Patients with a visit but no BP taken")).to eq("1")
      expect(find_in_csv(csv, row_index, "Patients under care as of #{period.end.strftime("%e-%b-%Y")}")).to eq("2")
      expect(csv[row_index][28..30].uniq).to eq([nil])
    end

    it "provides accurate numbers for facility sizes" do
      missed_visit_patient
      follow_up_patient
      patient_without_hypertension
      ltfu_patient
      RefreshReportingViews.new.refresh_v2

      result = service.report
      csv = CSV.parse(result)
      row_index = 5

      expect(find_in_csv(csv, row_index, "#")).to eq("Community facilities")
      expect(csv[row_index][1..3].uniq).to eq([nil])
      expect(find_in_csv(csv, row_index, "Facility size")).to eq("Community")
      expect(find_in_csv(csv, row_index, "Estimated hypertensive population")).to eq(nil)
      expect(find_in_csv(csv, row_index, "Total registrations")).to eq("3")
      expect(find_in_csv(csv, row_index, "Total assigned patients")).to eq("3")
      expect(find_in_csv(csv, row_index, "Lost to follow-up patients")).to eq("1")
      dead = find_in_csv(csv, row_index, "Dead patients (All-time as of #{Date.current.strftime("%e-%b-%Y")})")
      expect(dead).to eq("0")
      expect(find_in_csv(csv, row_index, "Patients under care as of #{period.adjusted_period.end.strftime("%e-%b-%Y")}")).to eq("2")
      new_registrations = csv[row_index][11..16]
      expect(new_registrations).to eq(%w[0 0 2 0 0 0])
      follow_ups = csv[row_index][17..22]
      expect(follow_ups).to eq(%w[0 0 0 1 0 0])
      expect(find_in_csv(csv, row_index, "Patients with BP controlled")).to eq("1")
      expect(find_in_csv(csv, row_index, "Patients with BP not controlled")).to eq("0")
      expect(find_in_csv(csv, row_index, "Patients with a missed visit")).to eq("0")
      expect(find_in_csv(csv, row_index, "Patients with a visit but no BP taken")).to eq("1")
      expect(find_in_csv(csv, row_index, "Patients under care as of #{period.end.strftime("%e-%b-%Y")}")).to eq("2")
      expect(csv[row_index][28..30].uniq).to eq([nil])
    end

    it "provides accurate numbers for individual facilities" do
      missed_visit_patient
      patient_without_hypertension
      ltfu_patient
      RefreshReportingViews.new.refresh_v2

      result = service.report
      csv = CSV.parse(result)
      row_index = 7

      expect(find_in_csv(csv, row_index, "#")).to eq("1")
      expect(find_in_csv(csv, row_index, "Block")).to eq(facility1.block)
      expect(find_in_csv(csv, row_index, "Facility")).to eq(facility1.name)
      expect(find_in_csv(csv, row_index, "Facility type")).to eq(facility1.source.facility_type)
      expect(find_in_csv(csv, row_index, "Facility size")).to eq(facility1.source.facility_size.capitalize)
      expect(find_in_csv(csv, row_index, "Estimated hypertensive population")).to eq(nil)
      expect(find_in_csv(csv, row_index, "Total registrations")).to eq("2")
      expect(find_in_csv(csv, row_index, "Total assigned patients")).to eq("2")
      expect(find_in_csv(csv, row_index, "Lost to follow-up patients")).to eq("1")
      dead = find_in_csv(csv, row_index, "Dead patients (All-time as of #{Date.current.strftime("%e-%b-%Y")})")
      expect(dead).to eq("0")
      expect(find_in_csv(csv, row_index, "Patients under care as of #{period.adjusted_period.end.strftime("%e-%b-%Y")}")).to eq("1")
      new_registrations = csv[row_index][11..16]
      expect(new_registrations).to eq(%w[0 0 1 0 0 0])
      follow_ups = csv[row_index][17..22]
      expect(follow_ups).to eq(%w[0 0 0 0 0 0])
      expect(find_in_csv(csv, row_index, "Patients with BP controlled")).to eq("0")
      expect(find_in_csv(csv, row_index, "Patients with BP not controlled")).to eq("0")
      expect(find_in_csv(csv, row_index, "Patients with a missed visit")).to eq("0")
      expect(find_in_csv(csv, row_index, "Patients with a visit but no BP taken")).to eq("1")
      expect(find_in_csv(csv, row_index, "Patients with a visit but no BP taken")).to eq("1")
      expect(find_in_csv(csv, row_index, "Patients under care as of #{period.end.strftime("%e-%b-%Y")}")).to eq("1")
      expect(csv[row_index][28..30].uniq).to eq([nil])
    end

    it "scopes the report to the provided period" do
      old_period = Period.month("July 2018")
      result = described_class.new(region, old_period).report
      csv = CSV.parse(result)
      column_headers = csv[2]
      first_month_index = 11
      last_month_index = 16
      expect(column_headers[first_month_index]).to eq("Feb-2018")
      expect(column_headers[last_month_index]).to eq("Jul-2018")
    end
  end
end
