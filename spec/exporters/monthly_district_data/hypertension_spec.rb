require "rails_helper"

describe MonthlyDistrictData::Hypertension do
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
  let(:facility1) { create(:facility, block: "Block 1 - alphabetically first", facility_group: facility_group, facility_size: :community) }
  let(:facility2) { create(:facility, block: "Block 2 - alphabetically second", facility_group: facility_group, facility_size: :community) }
  let(:region) { facility1.region.district_region }
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

  let(:medications_dispensed_patients) {
    create(:appointment, facility: facility1, scheduled_date: 10.days.from_now, device_created_at: Date.today, patient: create(:patient, recorded_at: 1.year.ago))
    create(:appointment, facility: facility2, scheduled_date: 10.days.from_now, device_created_at: Date.today, patient: create(:patient, recorded_at: 1.year.ago))
    create(:appointment, facility: facility2, scheduled_date: Date.today, device_created_at: 32.days.ago, patient: create(:patient, recorded_at: 1.year.ago))
    create(:appointment, facility: facility1, scheduled_date: Date.today, device_created_at: 63.days.ago, patient: create(:patient, recorded_at: 1.year.ago))
  }

  let(:months) {
    period.downto(5).reverse.map(&:to_s)
  }

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
        "Hypertension patients under care as of #{period.end.strftime("%e-%b-%Y")}", *(months * 2),
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

    describe "#header_row" do
      it "returns header row" do
        expect(described_class.new(region: region, period: period, medications_dispensation_enabled: false).header_row).to eq(headers)
      end
    end

    describe "#section_row" do
      it "returns section row" do
        expect(described_class.new(region: region, period: period, medications_dispensation_enabled: false).section_row).to eq(sections)
      end
    end

    describe "#district_row" do
      it "returns district row" do
      end
    end

    describe "#facility_size_rows" do
      it "returns facility size row" do
      end
    end

    describe "#facility_rows" do
      it "returns facility row" do
      end
    end
  end
end
