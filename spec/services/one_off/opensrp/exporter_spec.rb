require "rails_helper"

describe OneOff::Opensrp::Exporter do
  context "configuration" do
    let(:config_path) { Rails.root.join("tmp", "mock_opensrp_config.yml") }
    let(:the_config) { described_class::Config.new config_path }

    before do
      config_content = <<-YAML
      time_boundaries:
        report_start: 2001-01-01
        report_end: 2002-02-02
      facilities:
        d1dbd3c6-26bb-48e7-aa89-bc8a0b2bf75b:
          name: Health Facility 1
          practitioner_id: 0c375fe8-b38f-484e-aa64-c02750ee183b
          organization_id: d3363aea-66ad-4370-809a-8e4436a4218f
          care_team_id: 1c8100b5-222b-4815-ba4d-3ebde537c6ce
          location_id: ABC01230123
      YAML
      File.write config_path, config_content
    end

    after do
      File.delete(config_path) if File.exist?(config_path)
    end

    it "parses :report_start" do
      expect(the_config.report_start).to eq(Date.parse("2001-01-01"))
    end

    it "parses :report_end" do
      expect(the_config.report_end).to eq(Date.parse("2002-02-02"))
    end

    it "parses :facilities to export" do
      facility_keys = %i[
        care_team_id
        location_id
        name
        organization_id
        practitioner_id
      ]
      expect(the_config.facilities.size).to eq 1
      # This weird quirk is because Hash#first returns an array [key, value]
      facility_spec = the_config.facilities.first.last
      expect(facility_spec[:name]).to eq "Health Facility 1"
      expect(facility_spec.keys.map(&:to_sym)).to match_array(facility_keys)
    end

    it "parses :time_window" do
      expect(the_config.time_window).to eq(the_config.report_start..the_config.report_end)
    end
  end

  describe "initialization" do
    let(:valid_config) { "config.yml" }
    let(:valid_output) { "output.json" }

    it "raises an error for non-YAML config files" do
      expect { described_class.new("config.txt", valid_output) }.to raise_error("Config file should be YAML")
    end

    it "raises an error for non-JSON output files" do
      expect { described_class.new(valid_config, "output.txt") }.to raise_error("Output file should be JSON")
    end

    it "expects config to be YAML, and output to be JSON" do
      allow(described_class::Config).to receive(:new)
      nulloger = ActiveSupport::Logger.new("/dev/null")
      expect { described_class.new(valid_config, valid_output, logger: nulloger) }.not_to raise_error
    end
  end

  describe "#call!" do
    # TODO: Setting this up is so involved!!!
    let(:district_with_facilities) { setup_district_with_facilities }
    let(:facility) { district_with_facilities[:facility_1] }
    let(:config_path) { Rails.root.join("tmp", "test_config.yml") }
    let(:output_path) { Rails.root.join("tmp", "test_output.json") }

    let(:patient) do
      create(:patient,
        registration_facility: facility,
        assigned_facility: facility,
        recorded_at: Date.parse("2001-06-15"))
    end

    %i[blood_pressure blood_sugar prescription_drug appointment].each do |association|
      the_date = Date.parse("2001-07-01")
      let(association) { create(association, patient: patient, recorded_at: the_date, created_at: the_date) }
    end

    let(:patient_exporter) { instance_double(OneOff::Opensrp::PatientExporter, export: "patient_res", export_registration_questionnaire_response: "patient_qr", export_registration_encounter: "patient_enc") }
    let(:bp_exporter) { instance_double(OneOff::Opensrp::BloodPressureExporter, export: "bp_res", export_encounter: "bp_enc") }
    let(:bs_exporter) { instance_double(OneOff::Opensrp::BloodSugarExporter, export: "bs_res", export_encounter: "bs_enc", export_no_diabetes_observation: nil) }
    let(:drug_exporter) { instance_double(OneOff::Opensrp::PrescriptionDrugExporter, export_dosage_flag: "drug_flag", export_encounter: "drug_enc") }
    let(:appointment_exporter) { instance_double(OneOff::Opensrp::AppointmentExporter, export: "appt_res", export_encounter: "appt_enc") }
    let(:medical_history_exporter) { instance_double(OneOff::Opensrp::MedicalHistoryExporter, export: "mh_res", export_encounter: "mh_enc") }
    let(:encounter_generator) { instance_double(OneOff::Opensrp::EncounterGenerator, generate: "encounter_bundle") }

    subject(:exporter) { described_class.new(config_path.to_s, output_path.to_s) }

    before do
      config_content = <<-YAML
      time_boundaries:
        report_start: 2001-01-01
        report_end: 2002-02-02
      facilities:
        #{facility.id}:
          name: #{facility.name}
      YAML
      File.write(config_path, config_content)

      allow(OneOff::Opensrp::PatientExporter).to receive(:new).and_return(patient_exporter)
      allow(OneOff::Opensrp::BloodPressureExporter).to receive(:new).and_return(bp_exporter)
      allow(OneOff::Opensrp::BloodSugarExporter).to receive(:new).and_return(bs_exporter)
      allow(OneOff::Opensrp::PrescriptionDrugExporter).to receive(:new).and_return(drug_exporter)
      allow(OneOff::Opensrp::AppointmentExporter).to receive(:new).and_return(appointment_exporter)
      allow(OneOff::Opensrp::MedicalHistoryExporter).to receive(:new).and_return(medical_history_exporter)
      allow(OneOff::Opensrp::EncounterGenerator).to receive(:new).and_return(encounter_generator)

      allow(exporter).to receive(:write_audit_trail)
    end

    after do
      File.delete(config_path) if File.exist?(config_path)
      File.delete(output_path) if File.exist?(output_path)
    end

    it "selects patients assigned to the facilities" do
      expect(Patient).to receive(:where).with(assigned_facility_id: [facility.id]).and_call_original
      exporter.call!
    end

    it "delegates to the correct sub-exporter" do
      exporter = described_class.new(config_path.to_s, output_path.to_s)
      expect(OneOff::Opensrp::PatientExporter).to receive(:new).with(patient, a_kind_of(Hash))
      expect(OneOff::Opensrp::BloodPressureExporter).to receive(:new).with(blood_pressure, a_kind_of(Hash))
      expect(OneOff::Opensrp::BloodSugarExporter).to receive(:new).with(blood_sugar, a_kind_of(Hash))
      expect(OneOff::Opensrp::PrescriptionDrugExporter).to receive(:new).with(prescription_drug, a_kind_of(Hash))
      expect(OneOff::Opensrp::AppointmentExporter).to receive(:new).with(appointment, a_kind_of(Hash))
      expect(OneOff::Opensrp::MedicalHistoryExporter).to receive(:new).with(patient.medical_history, a_kind_of(Hash))
      exporter.call!
    end

    it "tallies the export correctly" do
      # Because `let(…) { ... }` is lazy, we have to force it
      blood_pressure
      blood_sugar
      prescription_drug
      appointment

      exporter.call!

      expect(exporter.tally[:patients]).to eq(1)
      expect(exporter.tally[:observation]).to eq(2)
      expect(exporter.tally[:flags]).to eq(1)
      expect(exporter.tally[:appointments]).to eq(1)
      expect(exporter.tally[:conditions]).to eq(1)
      expect(exporter.tally[:encounters]).to eq(6)
    end

    context "with time filtering" do
      let(:considered) { patient }
      let(:ignored) do
        create(:patient,
          registration_facility: facility,
          assigned_facility: facility,
          recorded_at: Date.parse("1999-09-09"))
      end

      it "does not select patients outside the time window" do
        expect(OneOff::Opensrp::PatientExporter).to receive(:new).with(considered, a_kind_of(Hash)).and_return(patient_exporter)
        expect(OneOff::Opensrp::PatientExporter).not_to receive(:new).with(ignored, a_kind_of(Hash))
        exporter.call!
        expect(exporter.tally[:patients]).to eq 1
      end
    end
  end
end
