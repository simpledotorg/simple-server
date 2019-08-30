require 'rails_helper'
require 'yaml'

RSpec.describe 'generate:seed:generate_data' do
  include RakeTestHelper

  let!(:env) { ENV.fetch('SIMPLE_SERVER_ENV') }
  let! (:seed_config) { YAML.load_file('config/seed.yml').fetch(env) }
  let!(:overdue) { seed_config.dig('patients', 'traits').include?('overdue') }
  let!(:hypertensive) { seed_config.dig('patients', 'traits').include?('hypertensive') }
  let!(:user) { create(:user, registration_facility: create(:facility, facility_group: create(:facility_group, organization: create(:organization)))) }
  let!(:patient_factor) { seed_config.dig('patients', 'count') }

  it 'generates correct number of patients data' do
    expect { invoke_task('generate:seed:generate_data[1]') }.to change { user.registered_patients.count }.by(patient_factor * (patient_factor + 1))
  end

  it 'generates the correct number of blood pressures' do
    bp_factor = seed_config.dig('patients', 'blood_pressures')

    expect { invoke_task('generate:seed:generate_data[1]') }.to change { user.blood_pressures.count }.by(4 * patient_factor * (bp_factor * (bp_factor + 1)))
  end

  it 'generates the correct number of appointments' do
    appointment_factor = seed_config.dig('patients', 'appointments')

    expect { invoke_task('generate:seed:generate_data[1]') }.to change { Appointment.count }.by(2 * patient_factor * (appointment_factor * (appointment_factor + 1)))
  end

  it 'generates the correct number of medical histories' do
    med_history_factor = seed_config.dig('patients', 'medical_histories')

    expect { invoke_task('generate:seed:generate_data[1]') }.to change { MedicalHistory.count }.by(2 * patient_factor * (med_history_factor * (med_history_factor + 1)))
  end

  it 'generates the correct number of prescription drugs' do
    prescription_drugs_factor = seed_config.dig('patients', 'prescription_drugs')

    expect { invoke_task('generate:seed:generate_data[1]') }.to change { PrescriptionDrug.count }.by(patient_factor * (prescription_drugs_factor * (prescription_drugs_factor + 1)))
  end

  context 'overdue', if: :overdue do
    it 'has overdue appointments' do
      appointment_factor = seed_config.dig('patients', 'appointments')

      expect { invoke_task('generate:seed:generate_data[1]') }.to change { Appointment.overdue.count }.by(patient_factor * (appointment_factor * (appointment_factor + 1)))
    end
  end

  context 'hypertensive', if: :hypertensive do
    it 'has hypertensive patients' do
      bp_factor = seed_config.dig('patients', 'blood_pressures')

      expect { invoke_task('generate:seed:generate_data[1]') }.to change { BloodPressure.hypertensive.count }.by(3 * patient_factor * (bp_factor * (bp_factor + 1)))
    end
  end
end