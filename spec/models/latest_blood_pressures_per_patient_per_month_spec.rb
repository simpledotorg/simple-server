require "rails_helper"

RSpec.describe LatestBloodPressuresPerPatientPerMonth, type: :model do
  def refresh_views
    described_class.refresh
  end

  def refresh_views_with_pg_set_to_reporting_time_zone
    original = ActiveRecord::Base.connection.execute("SELECT current_setting('TIMEZONE')").first["current_setting"]
    ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{Period::REPORTING_TIME_ZONE}'")
    described_class.refresh
    # We need to reset to original TZ here, otherwise the reporting time zone will persist for the length of a
    # test and break assertions later
    ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE #{original}")
  end

  describe "Associations" do
    it { should belong_to(:patient) }
  end

  describe "handling time zones" do
    it "stores mat view timestamps in UTC to stay consistent with the source application tables" do
      # Sanity checks - make sure we are all UTC.
      expect(Time.zone.name).to eq("UTC")
      expect(ActiveRecord::Base.default_timezone).to eq(:utc)

      timestamp_in_utc = Time.zone.parse("January 15th 2018 12:00:00 UTC")
      timestamp_in_ist = timestamp_in_utc.in_time_zone(Period::REPORTING_TIME_ZONE)
      # We keep the timezone in UTC for creation of our fixtures.
      # This better emulates what happens in the app, because our sync APIs DO NOT have a default time zone
      # set (so we default to UTC), and I assume (and hope) that times get correctly parsed from the string
      # format sent by clients (probably ISO8601 from the JSON payloads).
      ltfu_patient, bp = Timecop.freeze(timestamp_in_utc) do
        ltfu_patient = create(:patient)
        bp = create(:blood_pressure, patient: ltfu_patient)
        [ltfu_patient, bp]
      end

      # We now switch to our reporting time zone, which represents the state where we are either
      #   1) populating materialized views
      #   2) retrieving data to show in reports
      # This is to verify that times are consistent and correct and respect Rails auto conversion to TimeWithZone
      Time.use_zone(Period::REPORTING_TIME_ZONE) do
        expect(Time.zone.name).to eq("Asia/Kolkata")
        refresh_views_with_pg_set_to_reporting_time_zone
        mat_view_row = described_class.find_by!(patient: ltfu_patient)

        raw_recorded_at = described_class.connection.select_one("SELECT patient_recorded_at FROM #{described_class.table_name}")
        expect(raw_recorded_at["patient_recorded_at"]).to eq("2018-01-15 12:00:00")
        raw_recorded_at_in_utc = described_class.connection.select_one("SELECT patient_recorded_at AT TIME ZONE 'UTC' as patient_recorded_at FROM #{described_class.table_name}")
        expect(raw_recorded_at_in_utc["patient_recorded_at"]).to eq("2018-01-15 12:00:00+00")

        expect(mat_view_row.patient_recorded_at).to eq(ltfu_patient.recorded_at)
        expect(mat_view_row.bp_recorded_at).to eq(bp.recorded_at)

        expect(ltfu_patient.recorded_at).to eq(timestamp_in_utc)
        expect(ltfu_patient.recorded_at).to eq(timestamp_in_ist) # Note that these are equal, even with different time zones
        expect(mat_view_row.patient_recorded_at).to eq(timestamp_in_utc)
      end

      mat_view_row = described_class.find_by!(patient: ltfu_patient)
      expect(mat_view_row.patient_recorded_at).to eq(ltfu_patient.recorded_at)
      expect(mat_view_row.bp_recorded_at).to eq(bp.recorded_at)
    end
  end

  describe "Materialized view query" do
    let(:months) { [1, 2, 3].map { |n| n.months.ago } }
    let(:facilities) { create_list(:facility, 2) }
    let(:patients) { facilities.map { |facility| create(:patient, registration_facility: facility) } }

    def create_blood_pressures
      facilities.map { |facility|
        months.map do |month|
          patients.map do |patient|
            create_list(:blood_pressure, 2, facility: facility, recorded_at: month, patient: patient)
          end
        end
      }.flatten
    end

    it "returns a row per patient per month" do
      Timecop.travel("1 Oct 2019") do
        create_blood_pressures
        LatestBloodPressuresPerPatientPerMonth.refresh
      end
      expect(LatestBloodPressuresPerPatientPerMonth.all.count).to eq(6)
    end

    it "returns at least one row per patient" do
      Timecop.travel("1 Oct 2019") do
        create_blood_pressures
        LatestBloodPressuresPerPatientPerMonth.refresh
      end

      expect(LatestBloodPressuresPerPatientPerMonth.all.pluck(:patient_id).uniq).to match_array(patients.map(&:id))
    end
  end

  describe "assigned facility" do
    it "stores the assigned facility" do
      facility = create(:facility)
      patient = create(:patient, assigned_facility: facility)
      blood_pressure = create(:blood_pressure, patient: patient)

      described_class.refresh

      expect(described_class.find_by_bp_id(blood_pressure.id).assigned_facility_id).to eq facility.id
    end
  end

  describe "patient status and medical history fields" do
    it "stores and updates patient status" do
      patient_1 = create(:patient, status: :migrated)
      patient_2 = create(:patient, status: :dead)

      create(:blood_pressure, patient: patient_1)
      create(:blood_pressure, patient: patient_2)

      LatestBloodPressuresPerPatientPerMonth.refresh

      bp_per_month_1 = LatestBloodPressuresPerPatientPerMonth.find_by!(patient_id: patient_1.id)
      expect(bp_per_month_1.patient_status).to eq("migrated")
      bp_per_month_2 = LatestBloodPressuresPerPatientPerMonth.find_by!(patient_id: patient_2.id)
      expect(bp_per_month_2.patient_status).to eq("dead")

      patient_1.update!(status: :active)

      LatestBloodPressuresPerPatientPerMonth.refresh

      bp_per_month_1 = LatestBloodPressuresPerPatientPerMonth.find_by!(patient_id: patient_1.id)
      expect(bp_per_month_1.patient_status).to eq("active")
    end

    it "stores and updates medical_history_hypertension" do
      patient_1 = create(:patient)
      patient_2 = create(:patient, :without_hypertension)
      patient_3 = create(:patient, :without_medical_history)

      create(:blood_pressure, patient: patient_1)
      create(:blood_pressure, patient: patient_2)
      create(:blood_pressure, patient: patient_3)

      LatestBloodPressuresPerPatientPerMonth.refresh

      bp_per_month_1 = LatestBloodPressuresPerPatientPerMonth.find_by!(patient_id: patient_1.id)
      expect(bp_per_month_1.medical_history_hypertension).to eq("yes")
      bp_per_month_2 = LatestBloodPressuresPerPatientPerMonth.find_by!(patient_id: patient_2.id)
      expect(bp_per_month_2.medical_history_hypertension).to eq("no")
      bp_per_month_3 = LatestBloodPressuresPerPatientPerMonth.find_by!(patient_id: patient_3.id)
      expect(bp_per_month_3.medical_history_hypertension).to be_nil
    end
  end
end
