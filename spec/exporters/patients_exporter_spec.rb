require 'rails_helper'

RSpec.describe PatientsExporter do
  include QuarterHelper

  let!(:facility) { create(:facility) }
  let!(:patient) { create(:patient, registration_facility: facility, status: 'dead') }
  let!(:blood_pressure) { create(:blood_pressure, :critical, facility: facility, patient: patient) }
  let!(:appointment) { create(:appointment, :overdue, facility: facility, patient: patient) }
  let!(:prescription_drug_1) { create(:prescription_drug, patient: patient) }
  let!(:prescription_drug_2) { create(:prescription_drug, patient: patient) }
  let(:now) { Time.current }

  let(:timestamp) do
    [
      'Report generated at:',
      now
    ]
  end

  let(:headers) do
    [
      'Registration Date',
      'Registration Quarter',
      'Patient died?',
      'Patient Name',
      'Patient Age',
      'Patient Gender',
      'Patient Phone Number',
      'Patient Village/Colony',
      'Patient District',
      'Patient State',
      'Registration Facility Name',
      'Registration Facility Type',
      'Registration Facility District',
      'Registration Facility State',
      'Latest BP Systolic',
      'Latest BP Diastolic',
      'Latest BP Date',
      'Latest BP Quarter',
      'Latest BP Facility Name',
      'Latest BP Facility Type',
      'Latest BP Facility District',
      'Latest BP Facility State',
      'Follow-up Facility',
      'Follow-up Date',
      'Days Overdue',
      'Risk Level',
      'BP Passport ID',
      'Simple Patient ID',
      'Medication 1',
      'Dosage 1',
      'Medication 2',
      'Dosage 2',
      'Medication 3',
      'Dosage 3',
      'Medication 4',
      'Dosage 4',
      'Medication 5',
      'Dosage 5'
    ]
  end

  let(:fields) do
    [
      I18n.l(patient.recorded_at),
      quarter_string(patient.recorded_at),
      'Died',
      patient.full_name,
      patient.current_age,
      patient.gender.capitalize,
      patient.phone_numbers.last&.number,
      patient.address.village_or_colony,
      patient.address.district,
      patient.address.state,
      facility.name,
      facility.facility_type,
      facility.district,
      facility.state,
      blood_pressure.systolic,
      blood_pressure.diastolic,
      I18n.l(blood_pressure.recorded_at),
      quarter_string(blood_pressure.recorded_at),
      blood_pressure.facility.name,
      blood_pressure.facility.facility_type,
      blood_pressure.facility.district,
      blood_pressure.facility.state,
      appointment.facility.name,
      appointment.scheduled_date.to_s(:rfc822),
      appointment.days_overdue,
      'High',
      patient.latest_bp_passport&.shortcode,
      patient.id,
      prescription_drug_1.name,
      prescription_drug_1.dosage,
      prescription_drug_2.name,
      prescription_drug_2.dosage
    ]
  end

  before do
    allow(patient).to receive(:high_risk?).and_return(true)
  end

  describe '#csv' do
    let(:patient_batch) { Patient.where(id: patient.id) }

    it 'generates a CSV of patient records' do
      travel_to now do
        expect(subject.csv(Patient.all)).to eq(timestamp.to_csv + headers.to_csv + fields.to_csv)
      end
    end

    it 'generates a blank CSV (only headers) if no patients exist' do
      travel_to now do
        expect(subject.csv(Patient.none)).to eq(timestamp.to_csv + headers.to_csv)
      end
    end

    it 'uses fetches patients in batches' do
      expect_any_instance_of(facility.registered_patients.class)
        .to receive(:in_batches).and_return([patient_batch])

      subject.csv(facility.registered_patients)
    end
  end
end
