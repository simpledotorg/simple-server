require "rails_helper"

describe MonthlyDistrictData::Diabetes do
  around do |example|
    # This is in the style of ReportingHelpers::freeze_time_for_reporting_specs.
    # Since FacilityAppointmentScheduledDays only keeps the last 6 months of data, the date cannot be a
    # fixed point in time like the spec helper.
    Timecop.freeze("#{Date.today.end_of_month} 23:00 IST") do
      example.run
    end
  end

  let(:organization) { FactoryBot.create(:organization) }
  let(:facility_group) { create(:facility_group, organization: organization) }
  let(:facility1) { create(:facility, name: "Facility 1", block: "Block 1 - alphabetically first", facility_group: facility_group, facility_size: :community, enable_diabetes_management: true) }
  let(:facility2) { create(:facility, name: "Facility 2", block: "Block 2 - alphabetically second", facility_group: facility_group, facility_size: :community, enable_diabetes_management: true) }
  let(:region) { facility1.region.district_region }
  let(:period) { Period.month(Date.today) }
  let(:missed_visit_patient) do
    patient = create(:patient, :diabetes, recorded_at: 3.months.ago, assigned_facility: facility1, registration_facility: facility1)
    create(:appointment, creation_facility: facility1, scheduled_date: 2.months.ago, patient: patient)
    patient
  end
  let(:follow_up_patient) do
    patient = create(:patient, :diabetes, recorded_at: 3.months.ago, assigned_facility: facility2, registration_facility: facility2)
    create(:appointment, creation_facility: facility2, scheduled_date: 2.month.ago, patient: patient)
    create(:blood_sugar_with_encounter, :bs_below_200, facility: facility2, patient: patient, recorded_at: 2.months.ago)
    patient
  end
  let(:patient_without_diabetes) do
    create(:patient, :without_diabetes, recorded_at: 3.months.ago, assigned_facility: facility1, registration_facility: facility1)
  end
  let(:ltfu_patient) { create(:patient, :diabetes, recorded_at: 2.years.ago, assigned_facility: facility1, registration_facility: facility1) }

  let(:medications_dispensed_patients) {
    create(:appointment, facility: facility1, scheduled_date: 10.days.from_now, device_created_at: Date.today, patient: create(:patient, :diabetes, recorded_at: 1.year.ago))
    create(:appointment, facility: facility2, scheduled_date: 10.days.from_now, device_created_at: Date.today, patient: create(:patient, :diabetes, recorded_at: 1.year.ago))
    create(:appointment, facility: facility2, scheduled_date: Date.today, device_created_at: 32.days.ago, patient: create(:patient, :diabetes, recorded_at: 1.year.ago))
    create(:appointment, facility: facility1, scheduled_date: Date.today, device_created_at: 63.days.ago, patient: create(:patient, :diabetes, recorded_at: 1.year.ago))
  }

  let(:months) {
    period.downto(5).reverse.map(&:to_s)
  }

  context "when medication dispensation is disabled" do
    let(:sections) {
      [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
        "New diabetes registrations", nil, nil, nil, nil, nil,
        "Diabetes follow-up patients", nil, nil, nil, nil, nil,
        "Treatment status of diabetes patients under care", nil, nil, nil, nil, nil,
        "Diabetes drug availability", nil, nil]
    }

    let(:headers) {
      [
        "#",
        "Block",
        "Facility",
        "Facility type",
        "Facility size",
        "Estimated diabetic population",
        "Total diabetes registrations",
        "Total assigned diabetes patients",
        "Diabetes lost to follow-up patients",
        "Dead diabetic patients (All-time as of #{Date.current.strftime("%e-%b-%Y")})",
        "Diabetes patients under care as of #{period.end.strftime("%e-%b-%Y")}",
        *(months * 2),
        "Patients under care as of #{period.adjusted_period.end.strftime("%e-%b-%Y")}",
        "Patients with blood sugar < 200",
        "Patients with blood sugar 200-299",
        "Patients with blood sugar ≥ 300",
        "Patients with a missed visit",
        "Patients with a visit but no blood sugar taken",
        "Amlodipine",
        "ARBs/ACE Inhibitors",
        "Diuretic"
      ]
    }

    let(:data_service) { described_class.new(region: region, period: period, medications_dispensation_enabled: false) }

    describe "#header_row" do
      it "returns header row" do
        expect(data_service.header_row).to eq(headers)
      end
    end

    describe "#section_row" do
      it "returns section row" do
        expect(data_service.section_row).to eq(sections)
      end
    end

    describe "#district_row" do
      it "returns district row" do
        missed_visit_patient
        follow_up_patient
        patient_without_diabetes
        ltfu_patient
        medications_dispensed_patients

        RefreshReportingViews.refresh_v2

        expected_district_row = ["All facilities", nil, nil, nil, "All", nil, 3, 3, 1, 0, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 2, 1, 4, 0, 1, 0, 0, 0, 1, nil, nil, nil]
        district_row = data_service.district_row
        expect(district_row.count).to eq(32)
        expect(district_row).to eq(expected_district_row)
      end
    end

    describe "#facility_size_rows" do
      it "provides accurate numbers for facility sizes" do
        missed_visit_patient
        follow_up_patient
        patient_without_diabetes
        ltfu_patient
        medications_dispensed_patients

        RefreshReportingViews.refresh_v2

        expected_facility_size_rows = [["Community facilities", nil, nil, nil, "Community", nil, 3, 3, 1, 0, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 2, 1, 4, 0, 1, 0, 0, 0, 1, nil, nil, nil]]
        facility_size_rows = data_service.facility_size_rows
        expect(facility_size_rows.count).to eq(1)
        expect(facility_size_rows.first&.count).to eq(32)
        expect(facility_size_rows).to eq(expected_facility_size_rows)
      end
    end

    describe "#facility_rows" do
      it "provides accurate numbers for individual facilities" do
        missed_visit_patient
        follow_up_patient
        patient_without_diabetes
        ltfu_patient
        medications_dispensed_patients

        RefreshReportingViews.refresh_v2

        expected_facility_rows = [[1, "Block 1 - alphabetically first", "Facility 1", "PHC", "Community", nil, 2, 2, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0, 0, 1, nil, nil, nil],
          [2, "Block 2 - alphabetically second", "Facility 2", "PHC", "Community", nil, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 2, 0, 1, 0, 0, 0, 0, nil, nil, nil]]
        facility_rows = data_service.facility_rows
        expect(facility_rows.count).to eq(2)
        expect(facility_rows.first&.count).to eq(32)
        expect(facility_rows.second&.count).to eq(32)
        expect(facility_rows).to eq(expected_facility_rows)
      end
    end

    it "scopes the report to the provided period" do
      old_period = Period.current
      header_row = described_class.new(
        region: region,
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
        "New diabetes registrations", nil, nil, nil, nil, nil,
        "Diabetes follow-up patients", nil, nil, nil, nil, nil,
        "Treatment status of diabetes patients under care", nil, nil, nil, nil, nil,
        "Days of patient medications", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
        "Diabetes drug availability", nil, nil]
    }

    let(:sub_sections) {
      [
        nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
        months[3].to_s, nil, nil, nil,
        months[4].to_s, nil, nil, nil,
        months[5].to_s, nil, nil, nil,
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
        "Estimated diabetic population",
        "Total diabetes registrations",
        "Total assigned diabetes patients",
        "Diabetes lost to follow-up patients",
        "Dead diabetic patients (All-time as of #{Date.current.strftime("%e-%b-%Y")})",
        "Diabetes patients under care as of #{period.end.strftime("%e-%b-%Y")}", *(months * 2),
        "Patients under care as of #{period.adjusted_period.end.strftime("%e-%b-%Y")}",
        "Patients with blood sugar < 200",
        "Patients with blood sugar 200-299",
        "Patients with blood sugar ≥ 300",
        "Patients with a missed visit",
        "Patients with a visit but no blood sugar taken",
        *(["Patients with 0 to 14 days of medications", "Patients with 15 to 31 days of medications", "Patients with 32 to 62 days of medications", "Patients with 62+ days of medications"] * 3),
        "Amlodipine",
        "ARBs/ACE Inhibitors",
        "Diuretic"
      ]
    }

    let(:data_service) { described_class.new(region: region, period: period, medications_dispensation_enabled: true) }

    describe "#header_row" do
      it "returns header row" do
        expect(data_service.header_row).to eq(headers)
      end
    end

    describe "#section_row" do
      it "returns section row" do
        expect(data_service.section_row).to eq(sections)
      end
    end

    describe "#sub-section_row" do
      it "returns sub-section row" do
        expect(data_service.sub_section_row).to eq(sub_sections)
      end
    end

    describe "#district_row" do
      it "returns district row" do
        missed_visit_patient
        follow_up_patient
        patient_without_diabetes
        ltfu_patient
        medications_dispensed_patients

        RefreshReportingViews.refresh_v2

        expected_district_row = ["All facilities", nil, nil, nil, "All", nil, 3, 3, 1, 0, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 2, 1, 4, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 2, 0, 0, 0, nil, nil, nil]
        district_row = data_service.district_row
        expect(district_row.count).to eq(44)
        expect(district_row).to eq(expected_district_row)
      end
    end

    describe "#facility_size_rows" do
      it "provides accurate numbers for facility sizes" do
        missed_visit_patient
        follow_up_patient
        patient_without_diabetes
        ltfu_patient
        medications_dispensed_patients

        RefreshReportingViews.refresh_v2

        expected_facility_size_rows = [["Community facilities", nil, nil, nil, "Community", nil, 3, 3, 1, 0, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 2, 1, 4, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 2, 0, 0, 0, nil, nil, nil]]
        facility_size_rows = data_service.facility_size_rows
        expect(facility_size_rows.count).to eq(1)
        expect(facility_size_rows.first&.count).to eq(44)
        expect(facility_size_rows).to eq(expected_facility_size_rows)
      end
    end

    describe "#facility_rows" do
      it "provides accurate numbers for individual facilities" do
        missed_visit_patient
        follow_up_patient
        patient_without_diabetes
        ltfu_patient
        medications_dispensed_patients

        RefreshReportingViews.refresh_v2

        expected_facility_rows = [[1, "Block 1 - alphabetically first", "Facility 1", "PHC", "Community", nil, 2, 2, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, nil, nil, nil],
          [2, "Block 2 - alphabetically second", "Facility 2", "PHC", "Community", nil, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 2, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, nil, nil, nil]]
        facility_rows = data_service.facility_rows
        expect(facility_rows.count).to eq(2)
        expect(facility_rows.first&.count).to eq(44)
        expect(facility_rows.second&.count).to eq(44)
        expect(facility_rows).to eq(expected_facility_rows)
      end
    end

    it "scopes the report to the provided period" do
      old_period = Period.current
      header_row = described_class.new(
        region: region,
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
