require "rails_helper"

describe DrRai::TitrationQueryFactory, {reporting_spec: true} do
  around do |example|
    Timecop.freeze("June 28 2025 12:00 IST") do
      with_reporting_time_zone { example.run }
    end
  end

  let(:timezone) { Time.find_zone(Period::REPORTING_TIME_ZONE) }
  let(:this_month) { timezone.local(2025, 6, 1) }
  let(:last_month) { this_month - 1.month }
  let(:scheduled_date) { this_month + 9.days } # June 10
  let(:on_time_visit) { scheduled_date + 1.day }
  let(:late_visit) { scheduled_date + 10.days }

  let(:district) { setup_district_with_facilities }
  let(:facility_1) { district[:facility_1] }
  let(:facility_2) { district[:facility_2] }

  before do
    create(:protocol_drug, name: "Amlodipine", dosage: "5 mg", drug_category: :hypertension_ccb)
  end

  def follow_up_patient(assigned_facility:, visit_facility:, visit_at:, titrated:)
    patient = create(:patient, assigned_facility: assigned_facility, registration_facility: assigned_facility,
      recorded_at: this_month - 3.months)
    create(:prescription_drug, patient: patient, facility: assigned_facility, name: "Amlodipine", dosage: "5 mg",
      device_created_at: last_month + 5.days, device_updated_at: titrated ? visit_at : last_month + 5.days,
      is_deleted: titrated)
    create(:appointment, patient: patient, facility: assigned_facility, scheduled_date: scheduled_date,
      device_created_at: last_month + 10.days)
    create(:blood_pressure, :hypertensive, patient: patient, facility: visit_facility,
      recorded_at: visit_at, device_created_at: visit_at)
    if titrated
      create(:prescription_drug, patient: patient, facility: visit_facility, name: "Amlodipine", dosage: "10 mg",
        device_created_at: visit_at, device_updated_at: visit_at)
    end
    patient
  end

  def populate_and_fetch
    RefreshReportingViews.refresh_v2
    DrRai::DataService.populate(DrRai::Data::Titration, timeline: this_month.to_date..this_month.end_of_month.to_date)
    DrRai::Data::Titration.unscoped.where(month_date: this_month.to_date).index_by(&:facility_name)
  end

  describe "populating titration data" do
    before do
      follow_up_patient(assigned_facility: facility_1, visit_facility: facility_1, visit_at: on_time_visit, titrated: true)
      follow_up_patient(assigned_facility: facility_1, visit_facility: facility_1, visit_at: on_time_visit, titrated: false)
      follow_up_patient(assigned_facility: facility_1, visit_facility: facility_1, visit_at: late_visit, titrated: true)
      follow_up_patient(assigned_facility: facility_2, visit_facility: facility_1, visit_at: on_time_visit, titrated: true)
    end

    it "only counts patients who visited within 3 days of their scheduled appointment" do
      rows = populate_and_fetch

      expect(rows[facility_1.name]).to have_attributes(follow_up_count: 2, titrated_count: 1)
      expect(rows[facility_1.name].titration_rate).to be_within(0.01).of(50)
    end

    it "groups patients by their assigned facility, not where the BP was recorded" do
      rows = populate_and_fetch

      expect(rows[facility_2.name]).to have_attributes(follow_up_count: 1, titrated_count: 1)
      expect(rows[facility_2.name].titration_rate).to be_within(0.01).of(100)
    end

    it "adds an average row across facilities" do
      rows = populate_and_fetch

      expect(rows["average"]).to have_attributes(follow_up_count: 3, titrated_count: 2)
      expect(rows["average"].titration_rate).to be_within(0.01).of(66.67)
      expect(rows.keys).to contain_exactly(facility_1.name, facility_2.name, "average")
    end
  end
end
