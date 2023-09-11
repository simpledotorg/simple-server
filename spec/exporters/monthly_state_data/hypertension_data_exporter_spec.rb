require "rails_helper"

describe MonthlyStateData::HypertensionDataExporter do
  around do |example|
    # This is in the style of ReportingHelpers::freeze_time_for_reporting_specs.
    # Since FacilityAppointmentScheduledDays only keeps the last 6 months of data, the date cannot be a
    # fixed point in time like the spec helper.
    Timecop.freeze("#{Date.today.end_of_month} 23:00 IST") do
      example.run
    end
  end

  before(:all) do
    @organization = FactoryBot.create(:organization)
    @facility_group = create(:facility_group, organization: @organization)
    @facility1 = create(:facility, name: "Facility 1", block: "Block 1 - alphabetically first", facility_group: @facility_group, facility_size: :community)
    @facility2 = create(:facility, name: "Facility 2", block: "Block 2 - alphabetically second", facility_group: @facility_group, facility_size: :community)
    @state = @facility1.region.state_region
    @district = @facility1.region.district_region
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

    logger.debug "starting transaction"
    @fiber = Fiber.new do
      ActiveRecord::Base.transaction do
        # RefreshReportingViews.refresh_v2
        RefreshReportingViews.call(
          views: %w[
            Reports::PatientBloodPressure
            Reports::PatientVisit
            Reports::PatientFollowUp
            Reports::PatientState
            Reports::FacilityAppointmentScheduledDays
            Reports::FacilityState
          ]
        )
        Fiber.yield
        raise ActiveRecord::Rollback
      end
    end

    @fiber.resume
  end

  after(:all) do
    @fiber.resume
  end

  describe "#report" do
    context "when medications_dispensed is disabled" do
      let(:data_service) { described_class.new(region: @state, period: @period, medications_dispensation_enabled: false) }
      let(:sections) {
        [nil, nil, nil, nil, nil, nil, nil, nil, nil,
          "New hypertension registrations", nil, nil, nil, nil, nil,
          "Hypertension follow-up patients", nil, nil, nil, nil, nil,
          "Treatment status of hypertension patients under care", nil, nil, nil, nil,
          "Hypertension drug availability", nil, nil]
      }
      let(:headers) {
        [
          "#",
          "State",
          "District",
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

      describe "#state_row" do
        it "provides accurate numbers for the state" do
          expected_state_row = ["All districts", @state.name, nil, nil, 3, 3, 1, 0, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 2, 1, 4, 2, 1, 0, 0, 1, nil, nil, nil]
          state_row = data_service.state_row
          expect(state_row.count).to eq(29)
          expect(state_row).to eq(expected_state_row)
        end
      end

      describe "#district_rows" do
        it "provides accurate numbers for individual facilities" do
          expected_district_rows = [[1, @state.name.to_s, @district.name.to_s, nil, 3, 3, 1, 0, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 2, 1, 4, 2, 1, 0, 0, 1, nil, nil, nil]]
          district_rows = data_service.district_rows
          expect(district_rows[0].count).to eq(29)
          expect(district_rows).to eq(expected_district_rows)
        end
      end

      it "scopes the report to the provided period" do
        old_period = Period.current
        header_row = described_class.new(region: @state, period: old_period, medications_dispensation_enabled: false).header_row
        first_month_index = 9
        last_month_index = 14

        expect(header_row[first_month_index]).to eq(Period.month(5.month.ago).to_s)
        expect(header_row[last_month_index]).to eq(Period.current.to_s)
      end
    end

    context "when medications_dispensed is enabled" do
      let(:data_service) { described_class.new(region: @state, period: @period, medications_dispensation_enabled: true) }
      let(:sections) {
        [nil, nil, nil, nil, nil, nil, nil, nil, nil,
          "New hypertension registrations", nil, nil, nil, nil, nil,
          "Hypertension follow-up patients", nil, nil, nil, nil, nil,
          "Treatment status of hypertension patients under care", nil, nil, nil, nil,
          "Days of patient medications", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
          "Hypertension drug availability", nil, nil]
      }
      let(:sub_sections) {
        [
          nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
          @months[3].to_s, nil, nil, nil,
          @months[4].to_s, nil, nil, nil,
          @months[5].to_s, nil, nil, nil,
          nil, nil, nil
        ]
      }
      let(:headers) {
        [
          "#",
          "State",
          "District",
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
      let(:medications_dispensed_patients) {
        create(:appointment, facility: @facility1, scheduled_date: 10.days.from_now, device_created_at: Date.today, patient: create(:patient, recorded_at: 1.year.ago))
        create(:appointment, facility: @facility2, scheduled_date: 10.days.from_now, device_created_at: Date.today, patient: create(:patient, recorded_at: 1.year.ago))
        create(:appointment, facility: @facility2, scheduled_date: Date.today, device_created_at: 32.days.ago, patient: create(:patient, recorded_at: 1.year.ago))
        create(:appointment, facility: @facility1, scheduled_date: Date.today, device_created_at: 63.days.ago, patient: create(:patient, recorded_at: 1.year.ago))
      }

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

      describe "#sub_section_row" do
        it "returns sub-section row" do
          expect(data_service.sub_section_row).to eq(sub_sections)
        end
      end

      describe "#state_row" do
        it "provides accurate numbers for the state" do
          expected_state_row = ["All districts", @state.name, nil, nil, 3, 3, 1, 0, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 2, 1, 4, 2, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 2, 0, 0, 0, nil, nil, nil]
          state_row = data_service.state_row
          expect(state_row.count).to eq(41)
          expect(state_row).to eq(expected_state_row)
        end
      end

      describe "#district_rows" do
        it "provides accurate numbers for individual facilities" do
          expected_district_rows = [[1, @state.name.to_s, @district.name.to_s, nil, 3, 3, 1, 0, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 2, 1, 4, 2, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 2, 0, 0, 0, nil, nil, nil]]
          district_rows = data_service.district_rows
          expect(district_rows[0].count).to eq(41)
          expect(district_rows).to eq(expected_district_rows)
        end
      end

      it "scopes the report to the provided period" do
        old_period = Period.current
        header_row = described_class.new(region: @state, period: old_period, medications_dispensation_enabled: true).header_row
        first_month_index = 9
        last_month_index = 14
        expect(header_row[first_month_index]).to eq(Period.month(5.month.ago).to_s)
        expect(header_row[last_month_index]).to eq(Period.current.to_s)
      end
    end
  end
end
