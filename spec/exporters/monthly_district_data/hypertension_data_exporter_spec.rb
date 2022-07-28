require "rails_helper"

describe MonthlyDistrictData::HypertensionDataExporter do
  around do |example|
    # This is in the style of ReportingHelpers::freeze_time_for_reporting_specs.
    # Since FacilityAppointmentScheduledDays only keeps the last 6 months of data, the date cannot be a
    # fixed point in time like the spec helper.
    Timecop.freeze("#{Date.today.end_of_month} 23:00 IST") do
      example.run
    end
  end
  before do
    @organization = FactoryBot.create(:organization)
    @facility_group = create(:facility_group, organization: @organization)
    @facility1 = create(:facility, name: "Facility 1", block: "Block 1 - alphabetically first", facility_group: @facility_group, facility_size: :community)
    @facility2 = create(:facility, name: "Facility 2", block: "Block 2 - alphabetically second", facility_group: @facility_group, facility_size: :community)
    @region = @facility1.region.district_region
    @period = Period.month(Date.today)
    @missed_visit_patient = create(:patient, :hypertension, recorded_at: 3.months.ago, assigned_facility: @facility1, registration_facility: @facility1)
    create(:appointment, creation_facility: @facility1, scheduled_date: 2.months.ago, patient: @missed_visit_patient)

    @follow_up_patient = create(:patient, :hypertension, recorded_at: 3.months.ago, assigned_facility: @facility2, registration_facility: @facility2)
    create(:appointment, creation_facility: @facility2, scheduled_date: 2.month.ago, patient: @follow_up_patient)
    create(:bp_with_encounter, :under_control, facility: @facility2, patient: @follow_up_patient, recorded_at: 2.months.ago)

    @patient_without_hypertension = create(:patient, :without_hypertension, recorded_at: 3.months.ago, assigned_facility: @facility1, registration_facility: @facility1)

    @ltfu_patient = create(:patient, :hypertension, recorded_at: 2.years.ago, assigned_facility: @facility1, registration_facility: @facility1)

    # medications_dispensed_patients
    create(:appointment, facility: @facility1, scheduled_date: 10.days.from_now, device_created_at: Date.today, patient: create(:patient, recorded_at: 1.year.ago))
    create(:appointment, facility: @facility2, scheduled_date: 10.days.from_now, device_created_at: Date.today, patient: create(:patient, recorded_at: 1.year.ago))
    create(:appointment, facility: @facility2, scheduled_date: Date.today, device_created_at: 32.days.ago, patient: create(:patient, recorded_at: 1.year.ago))
    create(:appointment, facility: @facility1, scheduled_date: Date.today, device_created_at: 63.days.ago, patient: create(:patient, recorded_at: 1.year.ago))

    @months = @period.downto(5).reverse.map(&:to_s)

    RefreshReportingViews.refresh_v2
  end

  context "when medication dispensation is disabled" do
    let(:sections) {
      [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
        "New hypertension registrations", nil, nil, nil, nil, nil,
        "Hypertension follow-up patients", nil, nil, nil, nil, nil,
        "Treatment status of hypertension patients under care", nil, nil, nil, nil,
        "Hypertension drug availability", nil, nil]
    }

    let(:headers) {
      [
        "#",
        "Block",
        "Facility",
        "Facility type",
        "Facility size",
        "Estimated hypertensive population",
        "Total hypertension registrations",
        "Total assigned hypertension patients",
        "Hypertension lost to follow-up patients",
        "Dead hypertensive patients (All-time as of #{Date.current.strftime("%e-%b-%Y")})",
        "Hypertension patients under care as of #{@period.end.strftime("%e-%b-%Y")}",
        *(@months * 2),
        "Patients under care as of #{@period.adjusted_period.end.strftime("%e-%b-%Y")}",
        "Patients with BP controlled",
        "Patients with BP not controlled",
        "Patients with a missed visit",
        "Patients with a visit but no BP taken",
        "Amlodipine",
        "ARBs/ACE Inhibitors",
        "Diuretic"
      ]
    }

    let(:exporter) { described_class.new(region: @region, period: @period, medications_dispensation_enabled: false) }

    def find_in_csv(csv_data, row_index, column_name)
      headers = csv_data[2]
      column = headers.index(column_name)
      csv_data[row_index][column]
    end

    describe "#report" do
      it "produces valid csv data" do
        result = exporter.report
        expect {
          CSV.parse(result)
        }.not_to raise_error
      end

      it "includes the section name, headers, district data and facility data" do
        result = exporter.report
        csv = CSV.parse(result)
        expect(csv[0]).to eq(["Monthly facility data for #{@region.name} #{@period.to_date.strftime("%B %Y")}"])
        expect(csv[1]).to eq(sections)
        expect(csv[2]).to eq(headers)
        expect(csv[3][0]).to eq("All facilities")
        expect(csv[3][4]).to eq("All")
        expect(csv[5][0]).to eq("Community facilities")
        expect(csv[5][4]).to eq("Community")
        expect(csv[7].slice(0, 5)).to eq(["1", "Block 1 - alphabetically first", "Facility 1", "PHC", "Community"])
        expect(csv[8].slice(0, 5)).to eq(["2", "Block 2 - alphabetically second", "Facility 2", "PHC", "Community"])
      end
    end

    describe "#header_row" do
      it "returns header row" do
        expect(exporter.header_row).to eq(headers)
      end
    end

    describe "#section_row" do
      it "returns section row" do
        expect(exporter.section_row).to eq(sections)
      end
    end

    describe "#district_row" do
      it "returns district row" do
        expected_district_row = ["All facilities", nil, nil, nil, "All", nil, 3, 3, 1, 0, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 2, 1, 4, 2, 1, 0, 0, 1, nil, nil, nil]
        district_row = exporter.district_row
        expect(district_row.count).to eq(31)
        expect(district_row).to eq(expected_district_row)
      end
    end

    describe "#facility_size_rows" do
      it "provides accurate numbers for facility sizes" do
        expected_facility_size_rows = [["Community facilities", nil, nil, nil, "Community", nil, 3, 3, 1, 0, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 2, 1, 4, 2, 1, 0, 0, 1, nil, nil, nil]]
        facility_size_rows = exporter.facility_size_rows
        expect(facility_size_rows.count).to eq(1)
        expect(facility_size_rows.first&.count).to eq(31)
        expect(facility_size_rows).to eq(expected_facility_size_rows)
      end
    end

    describe "#facility_rows" do
      it "provides accurate numbers for individual facilities" do
        expected_facility_rows = [[1, "Block 1 - alphabetically first", "Facility 1", "PHC", "Community", nil, 2, 2, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 2, 1, 0, 0, 0, 1, nil, nil, nil],
          [2, "Block 2 - alphabetically second", "Facility 2", "PHC", "Community", nil, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 2, 1, 1, 0, 0, 0, nil, nil, nil]]
        facility_rows = exporter.facility_rows
        expect(facility_rows.count).to eq(2)
        expect(facility_rows.first&.count).to eq(31)
        expect(facility_rows.second&.count).to eq(31)
        expect(facility_rows).to eq(expected_facility_rows)
      end
    end

    it "scopes the report to the provided period" do
      old_period = Period.current
      header_row = described_class.new(
        region: @region,
        period: old_period,
        medications_dispensation_enabled: false
      ).header_row

      first_month_index = 11
      last_month_index = 16
      expect(header_row[first_month_index]).to eq(Period.month(5.month.ago).to_s)
      expect(header_row[last_month_index]).to eq(Period.current.to_s)
    end
  end

  context "when medication dispensation is enabled" do
    let(:sections) {
      [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
        "New hypertension registrations", nil, nil, nil, nil, nil,
        "Hypertension follow-up patients", nil, nil, nil, nil, nil,
        "Treatment status of hypertension patients under care", nil, nil, nil, nil,
        "Days of patient medications", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
        "Hypertension drug availability", nil, nil]
    }

    let(:sub_sections) {
      [
        nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
        @months[3].to_s, nil, nil, nil,
        @months[4].to_s, nil, nil, nil,
        @months[5].to_s, nil, nil, nil,
        nil, nil, nil
      ]
    }

    let(:headers) {
      [
        "#",
        "Block",
        "Facility",
        "Facility type",
        "Facility size",
        "Estimated hypertensive population",
        "Total hypertension registrations",
        "Total assigned hypertension patients",
        "Hypertension lost to follow-up patients",
        "Dead hypertensive patients (All-time as of #{Date.current.strftime("%e-%b-%Y")})",
        "Hypertension patients under care as of #{@period.end.strftime("%e-%b-%Y")}",
        *(@months * 2),
        "Patients under care as of #{@period.adjusted_period.end.strftime("%e-%b-%Y")}",
        "Patients with BP controlled",
        "Patients with BP not controlled",
        "Patients with a missed visit",
        "Patients with a visit but no BP taken",
        *(["Patients with 0 to 14 days of medications", "Patients with 15 to 31 days of medications", "Patients with 32 to 62 days of medications", "Patients with 62+ days of medications"] * 3),
        "Amlodipine",
        "ARBs/ACE Inhibitors",
        "Diuretic"
      ]
    }

    let(:exporter) { described_class.new(region: @region, period: @period, medications_dispensation_enabled: true) }

    def find_in_csv(csv_data, row_index, column_name)
      headers = csv_data[2]
      column = headers.index(column_name)
      csv_data[row_index][column]
    end

    describe "#report" do
      it "produces valid csv data" do
        result = exporter.report
        expect {
          CSV.parse(result)
        }.not_to raise_error
      end

      it "includes the section name, headers, district data and facility data" do
        result = exporter.report
        csv = CSV.parse(result)
        expect(csv[0]).to eq(["Monthly facility data for #{@region.name} #{@period.to_date.strftime("%B %Y")}"])
        expect(csv[1]).to eq(sections)
        expect(csv[2]).to eq(sub_sections)
        expect(csv[3]).to eq(headers)
        expect(csv[4][0]).to eq("All facilities")
        expect(csv[4][4]).to eq("All")
        expect(csv[6][0]).to eq("Community facilities")
        expect(csv[6][4]).to eq("Community")
        expect(csv[8].slice(0, 5)).to eq(["1", "Block 1 - alphabetically first", "Facility 1", "PHC", "Community"])
        expect(csv[9].slice(0, 5)).to eq(["2", "Block 2 - alphabetically second", "Facility 2", "PHC", "Community"])
      end
    end

    describe "#header_row" do
      it "returns header row" do
        expect(exporter.header_row).to eq(headers)
      end
    end

    describe "#section_row" do
      it "returns section row" do
        expect(exporter.section_row).to eq(sections)
      end
    end

    describe "#sub-section_row" do
      it "returns sub-section row" do
        expect(exporter.sub_section_row).to eq(sub_sections)
      end
    end

    describe "#district_row" do
      it "returns district row" do
        expected_district_row = ["All facilities", nil, nil, nil, "All", nil, 3, 3, 1, 0, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 2, 1, 4, 2, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 2, 0, 0, 0, nil, nil, nil]
        district_row = exporter.district_row
        expect(district_row.count).to eq(43)
        expect(district_row).to eq(expected_district_row)
      end
    end

    describe "#facility_size_rows" do
      it "provides accurate numbers for facility sizes" do
        expected_facility_size_rows = [["Community facilities", nil, nil, nil, "Community", nil, 3, 3, 1, 0, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 2, 1, 4, 2, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 2, 0, 0, 0, nil, nil, nil]]
        facility_size_rows = exporter.facility_size_rows
        expect(facility_size_rows.count).to eq(1)
        expect(facility_size_rows.first&.count).to eq(43)
        expect(facility_size_rows).to eq(expected_facility_size_rows)
      end
    end

    describe "#facility_rows" do
      it "provides accurate numbers for individual facilities" do
        expected_facility_rows = [[1, "Block 1 - alphabetically first", "Facility 1", "PHC", "Community", nil, 2, 2, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 2, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, nil, nil, nil],
          [2, "Block 2 - alphabetically second", "Facility 2", "PHC", "Community", nil, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, nil, nil, nil]]
        facility_rows = exporter.facility_rows
        expect(facility_rows.count).to eq(2)
        expect(facility_rows.first&.count).to eq(43)
        expect(facility_rows.second&.count).to eq(43)
        expect(facility_rows).to eq(expected_facility_rows)
      end
    end

    it "scopes the report to the provided period" do
      old_period = Period.current
      header_row = described_class.new(
        region: @region,
        period: old_period,
        medications_dispensation_enabled: true
      ).header_row

      first_month_index = 11
      last_month_index = 16
      expect(header_row[first_month_index]).to eq(Period.month(5.month.ago).to_s)
      expect(header_row[last_month_index]).to eq(Period.current.to_s)
    end
  end
end
