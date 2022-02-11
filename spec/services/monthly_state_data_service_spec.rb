require "rails_helper"

RSpec.describe MonthlyStateDataService, reporting_spec: true do
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
  let(:facility1) { create(:facility, facility_group: facility_group) }
  let(:facility2) { create(:facility, facility_group: facility_group) }
  let(:district) { facility1.region.district_region }
  let(:state) { facility1.region.state_region }
  let(:period) { Period.month(Date.today) }
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
  let(:months) { period.downto(5).reverse.map(&:to_s) }

  describe "#report" do
    context "when medications_dispensed is disabled" do
      let(:service) { described_class.new(state, period, medications_dispensation_enabled: false) }
      let(:sections) {
        [nil, nil, nil, nil, nil, nil, nil, nil, nil,
          "New Registrations", nil, nil, nil, nil, nil,
          "Follow-up patients", nil, nil, nil, nil, nil,
          "Treatment outcomes of patients under care", nil, nil, nil, nil,
          "Drug availability", nil, nil]
      }
      let(:headers) {
        [
          "#",
          "State",
          "District",
          "Estimated hypertensive population",
          "Total registrations",
          "Total assigned patients",
          "Lost to follow-up patients",
          "Dead patients (All-time as of #{Date.current.strftime("%e-%b-%Y")})",
          "Patients under care as of #{period.end.strftime("%e-%b-%Y")}", *(months * 2),
          "Patients under care as of #{period.adjusted_period.end.strftime("%e-%b-%Y")}",
          "Patients with BP controlled",
          "Patients with BP not controlled",
          "Patients with a missed visit",
          "Patients with a visit but no BP taken",
          "Amlodipine",
          "ARBs/ACE Inhibitors",
          "Diuretic"
        ]
      }

      def find_in_csv(csv_data, row_index, column_name)
        headers = csv_data[2]
        column = headers.index(column_name)
        csv_data[row_index][column]
      end

      it "produces valid csv data" do
        result = service.report
        expect {
          CSV.parse(result)
        }.not_to raise_error
      end

      it "includes the section name, sub-section name and headers" do
        result = service.report
        csv = CSV.parse(result)
        expect(csv[0]).to eq(["Monthly district data for #{state.name} #{period.to_date.strftime("%B %Y")}"])
        expect(csv[1]).to eq(sections)
        expect(csv[2]).to eq(headers)
        expect(csv[3][0]).to eq("All districts")
      end

      it "provides accurate numbers for the state" do
        missed_visit_patient
        follow_up_patient
        patient_without_hypertension
        ltfu_patient
        RefreshReportingViews.new.refresh_v2

        result = service.report
        csv = CSV.parse(result)
        region_row_index = 3

        expect(find_in_csv(csv, region_row_index, "#")).to eq("All districts")
        expect(find_in_csv(csv, region_row_index, "State")).to eq(state.name)
        expect(csv[region_row_index][2..3].uniq).to eq([nil])
        expect(find_in_csv(csv, region_row_index, "Total registrations")).to eq("3")
        expect(find_in_csv(csv, region_row_index, "Total assigned patients")).to eq("3")
        expect(find_in_csv(csv, region_row_index, "Lost to follow-up patients")).to eq("1")
        dead = find_in_csv(csv, region_row_index, "Dead patients (All-time as of #{Date.current.strftime("%e-%b-%Y")})")
        expect(dead).to eq("0")
        expect(find_in_csv(csv, region_row_index, "Patients under care as of #{period.adjusted_period.end.strftime("%e-%b-%Y")}")).to eq("2")
        new_registrations = csv[region_row_index][9..14]
        expect(new_registrations).to eq(%w[0 0 2 0 0 0])
        follow_ups = csv[region_row_index][15..20]
        expect(follow_ups).to eq(%w[0 0 0 1 0 0])
        expect(find_in_csv(csv, region_row_index, "Patients with BP controlled")).to eq("1")
        expect(find_in_csv(csv, region_row_index, "Patients with BP not controlled")).to eq("0")
        # expect(find_in_csv(csv, region_row_index, "Patients with a missed visit")).to eq("1")
        expect(find_in_csv(csv, region_row_index, "Patients with a visit but no BP taken")).to eq("1")
        expect(find_in_csv(csv, region_row_index, "Patients under care as of #{period.end.strftime("%e-%b-%Y")}")).to eq("2")
        expect(csv[region_row_index][26..28].uniq).to eq([nil])
      end

      it "provides accurate numbers for the districts" do
        missed_visit_patient
        patient_without_hypertension
        ltfu_patient
        RefreshReportingViews.new.refresh_v2

        result = service.report
        csv = CSV.parse(result)
        facility_row_index = 4

        expect(find_in_csv(csv, facility_row_index, "#")).to eq("1")
        expect(find_in_csv(csv, facility_row_index, "State")).to eq(state.name)
        expect(find_in_csv(csv, facility_row_index, "District")).to eq(district.name)
        expect(find_in_csv(csv, facility_row_index, "Estimated hypertensive population")).to eq(nil)
        expect(find_in_csv(csv, facility_row_index, "Total registrations")).to eq("2")
        expect(find_in_csv(csv, facility_row_index, "Total assigned patients")).to eq("2")
        expect(find_in_csv(csv, facility_row_index, "Lost to follow-up patients")).to eq("1")
        dead = find_in_csv(csv, facility_row_index, "Dead patients (All-time as of #{Date.current.strftime("%e-%b-%Y")})")
        expect(dead).to eq("0")
        expect(find_in_csv(csv, facility_row_index, "Patients under care as of #{period.adjusted_period.end.strftime("%e-%b-%Y")}")).to eq("1")
        new_registrations = csv[facility_row_index][9..14]
        expect(new_registrations).to eq(%w[0 0 1 0 0 0])
        follow_ups = csv[facility_row_index][15..20]
        expect(follow_ups).to eq(%w[0 0 0 0 0 0])
        expect(find_in_csv(csv, facility_row_index, "Patients with BP controlled")).to eq("0")
        expect(find_in_csv(csv, facility_row_index, "Patients with BP not controlled")).to eq("0")
        expect(find_in_csv(csv, facility_row_index, "Patients with a missed visit")).to eq("0")
        expect(find_in_csv(csv, facility_row_index, "Patients with a visit but no BP taken")).to eq("1")
        expect(find_in_csv(csv, facility_row_index, "Patients with a visit but no BP taken")).to eq("1")
        expect(find_in_csv(csv, facility_row_index, "Patients under care as of #{period.end.strftime("%e-%b-%Y")}")).to eq("1")
        expect(csv[facility_row_index][26..28].uniq).to eq([nil])
      end

      it "scopes the report to the provided period" do
        old_period = Period.current
        result = described_class.new(state, old_period, medications_dispensation_enabled: false).report
        csv = CSV.parse(result)
        column_headers = csv[2]
        first_month_index = 9
        last_month_index = 14
        expect(column_headers[first_month_index]).to eq(Period.month(5.month.ago).to_s)
        expect(column_headers[last_month_index]).to eq(Period.current.to_s)
      end
    end
    context "when medications_dispensed is enabled" do
      let(:service) { described_class.new(state, period, medications_dispensation_enabled: true) }
      let(:sections) {
        [nil, nil, nil, nil, nil, nil, nil, nil, nil,
          "New Registrations", nil, nil, nil, nil, nil,
          "Follow-up patients", nil, nil, nil, nil, nil,
          "Treatment outcomes of patients under care", nil, nil, nil, nil,
          "Days of patient medications", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
          "Drug availability", nil, nil]
      }
      let(:sub_sections) {
        [
          nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
          months[3].to_s, nil, nil, nil,
          months[4].to_s, nil, nil, nil,
          months[5].to_s, nil, nil, nil,
          nil, nil, nil
        ]
      }
      let(:headers) {
        [
          "#",
          "State",
          "District",
          "Estimated hypertensive population",
          "Total registrations",
          "Total assigned patients",
          "Lost to follow-up patients",
          "Dead patients (All-time as of #{Date.current.strftime("%e-%b-%Y")})",
          "Patients under care as of #{period.end.strftime("%e-%b-%Y")}", *(months * 2),
          "Patients under care as of #{period.adjusted_period.end.strftime("%e-%b-%Y")}",
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
      let(:medications_dispensed_patients) {
        create(:appointment, facility: facility1, scheduled_date: 10.days.from_now, device_created_at: Date.today, patient: create(:patient, recorded_at: 1.year.ago))
        create(:appointment, facility: facility2, scheduled_date: 10.days.from_now, device_created_at: Date.today, patient: create(:patient, recorded_at: 1.year.ago))
        create(:appointment, facility: facility2, scheduled_date: Date.today, device_created_at: 32.days.ago, patient: create(:patient, recorded_at: 1.year.ago))
        create(:appointment, facility: facility1, scheduled_date: Date.today, device_created_at: 63.days.ago, patient: create(:patient, recorded_at: 1.year.ago))
      }

      def find_in_csv(csv_data, row_index, column_name)
        headers = csv_data[3]
        column = headers.index(column_name)
        csv_data[row_index][column]
      end

      it "produces valid csv data" do
        result = service.report
        expect {
          CSV.parse(result)
        }.not_to raise_error
      end

      it "includes the section name, sub-section name and headers" do
        result = service.report
        csv = CSV.parse(result)
        expect(csv[0]).to eq(["Monthly district data for #{state.name} #{period.to_date.strftime("%B %Y")}"])
        expect(csv[1]).to eq(sections)
        expect(csv[2]).to eq(sub_sections)
        expect(csv[3]).to eq(headers)
        expect(csv[4][0]).to eq("All districts")
      end

      it "provides accurate numbers for the state" do
        missed_visit_patient
        follow_up_patient
        patient_without_hypertension
        ltfu_patient
        medications_dispensed_patients
        RefreshReportingViews.new.refresh_v2

        result = service.report
        csv = CSV.parse(result)
        region_row_index = 4

        expect(find_in_csv(csv, region_row_index, "#")).to eq("All districts")
        expect(find_in_csv(csv, region_row_index, "State")).to eq(state.name)
        expect(csv[region_row_index][2..3].uniq).to eq([nil])
        expect(find_in_csv(csv, region_row_index, "Total registrations")).to eq("3")
        expect(find_in_csv(csv, region_row_index, "Total assigned patients")).to eq("3")
        expect(find_in_csv(csv, region_row_index, "Lost to follow-up patients")).to eq("1")
        dead = find_in_csv(csv, region_row_index, "Dead patients (All-time as of #{Date.current.strftime("%e-%b-%Y")})")
        expect(dead).to eq("0")
        expect(find_in_csv(csv, region_row_index, "Patients under care as of #{period.adjusted_period.end.strftime("%e-%b-%Y")}")).to eq("2")
        new_registrations = csv[region_row_index][9..14]
        expect(new_registrations).to eq(%w[0 0 2 0 0 0])
        follow_ups = csv[region_row_index][15..20]
        expect(follow_ups).to eq(%w[0 0 0 1 0 0])
        expect(find_in_csv(csv, region_row_index, "Patients with BP controlled")).to eq("1")
        expect(find_in_csv(csv, region_row_index, "Patients with BP not controlled")).to eq("0")
        # expect(find_in_csv(csv, region_row_index, "Patients with a missed visit")).to eq("1")
        expect(find_in_csv(csv, region_row_index, "Patients with a visit but no BP taken")).to eq("1")
        expect(find_in_csv(csv, region_row_index, "Patients under care as of #{period.end.strftime("%e-%b-%Y")}")).to eq("2")
        expect(csv[region_row_index][29]).to eq("1")
        expect(csv[region_row_index][32]).to eq("1")
        expect(csv[region_row_index][34]).to eq("2")
        expect(csv[region_row_index][38..40].uniq).to eq([nil])
      end

      it "provides accurate numbers for the districts" do
        missed_visit_patient
        patient_without_hypertension
        medications_dispensed_patients
        ltfu_patient
        RefreshReportingViews.new.refresh_v2

        result = service.report
        csv = CSV.parse(result)
        facility_row_index = 5

        expect(find_in_csv(csv, facility_row_index, "#")).to eq("1")
        expect(find_in_csv(csv, facility_row_index, "State")).to eq(state.name)
        expect(find_in_csv(csv, facility_row_index, "District")).to eq(district.name)
        expect(find_in_csv(csv, facility_row_index, "Estimated hypertensive population")).to eq(nil)
        expect(find_in_csv(csv, facility_row_index, "Total registrations")).to eq("2")
        expect(find_in_csv(csv, facility_row_index, "Total assigned patients")).to eq("2")
        expect(find_in_csv(csv, facility_row_index, "Lost to follow-up patients")).to eq("1")
        dead = find_in_csv(csv, facility_row_index, "Dead patients (All-time as of #{Date.current.strftime("%e-%b-%Y")})")
        expect(dead).to eq("0")
        expect(find_in_csv(csv, facility_row_index, "Patients under care as of #{period.adjusted_period.end.strftime("%e-%b-%Y")}")).to eq("1")
        new_registrations = csv[facility_row_index][9..14]
        expect(new_registrations).to eq(%w[0 0 1 0 0 0])
        follow_ups = csv[facility_row_index][15..20]
        expect(follow_ups).to eq(%w[0 0 0 0 0 0])
        expect(find_in_csv(csv, facility_row_index, "Patients with BP controlled")).to eq("0")
        expect(find_in_csv(csv, facility_row_index, "Patients with BP not controlled")).to eq("0")
        expect(find_in_csv(csv, facility_row_index, "Patients with a missed visit")).to eq("0")
        expect(find_in_csv(csv, facility_row_index, "Patients with a visit but no BP taken")).to eq("1")
        expect(find_in_csv(csv, facility_row_index, "Patients with a visit but no BP taken")).to eq("1")
        expect(find_in_csv(csv, facility_row_index, "Patients under care as of #{period.end.strftime("%e-%b-%Y")}")).to eq("1")
        expect(csv[facility_row_index][29]).to eq("1")
        expect(csv[facility_row_index][32]).to eq("1")
        expect(csv[facility_row_index][34]).to eq("2")
        expect(csv[facility_row_index][38..40].uniq).to eq([nil])
      end

      it "scopes the report to the provided period" do
        old_period = Period.current
        result = described_class.new(state, old_period, medications_dispensation_enabled: true).report
        csv = CSV.parse(result)
        column_headers = csv[3]
        first_month_index = 9
        last_month_index = 14
        expect(column_headers[first_month_index]).to eq(Period.month(5.month.ago).to_s)
        expect(column_headers[last_month_index]).to eq(Period.current.to_s)
      end
    end
  end
end
