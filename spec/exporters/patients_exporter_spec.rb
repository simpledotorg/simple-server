require 'rails_helper'

RSpec.describe PatientsExporter do
  include QuarterHelper

  let!(:facility) { create(:facility) }
  let!(:patient) { create(:patient, registration_facility: facility) }
  let!(:blood_pressure) { create(:blood_pressure, facility: facility, patient: patient) }
  let!(:appointment) { create(:appointment, :overdue, facility: facility, patient: patient) }

  let(:headers) do
    [
      'Registration Date',
      'Registration Quarter',
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
      'Days Overdue',
      'Risk Level',
      'BP Passport ID',
      'Simple Patient ID'
    ]
  end

  let(:fields) do
    [
      I18n.l(patient.recorded_at),
      quarter_string(patient.recorded_at),
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
      appointment.days_overdue,
      'High',
      patient.latest_bp_passport&.shortcode,
      patient.id
    ]
  end

  before do
    allow(patient).to receive(:high_risk?).and_return(true)
  end

  describe '#csv' do
    it 'generates a CSV of patient records' do
      expect(subject.csv(Patient.all)).to eq(headers.to_csv + fields.to_csv)
    end

    it 'generates a blank CSV (only headers) if no patients exist' do
      expect(subject.csv(Patient.none)).to eq(headers.to_csv)
    end

    it 'uses fetches patients in batches' do
      expect_any_instance_of(facility.registered_patients.class)
        .to receive(:in_batches).and_return([[patient]])

      subject.csv(facility.registered_patients)
    end
  end
end
