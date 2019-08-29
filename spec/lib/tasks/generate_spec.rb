require 'rails_helper'
require 'yaml'

RSpec.describe 'generate:seed:generate_data' do
  include RakeTestHelper

  let!(:env) { ENV.fetch('SIMPLE_SERVER_ENV') }
  let! (:seed_config) { YAML.load_file('config/seed.yml').fetch(env) }
  let!(:overdue) { seed_config.dig('patients', 'traits').include?('overdue') }
  let!(:hypertensive) { seed_config.dig('patients', 'traits').include?('hypertensive') }
  let!(:user) { create(:user, registration_facility: create(:facility, facility_group: create(:facility_group, organization: create(:organization)))) }
  let!(:user_patient_count) { user.registered_patients.count }

  before do
    invoke_task('generate:seed:generate_data[1]')
  end

  context 'user-supplied values' do
    it 'generates correct patient data' do
      expect(user.registered_patients.count).to eq user_patient_count + seed_config.dig('patients', 'count')

      expect(Patient.count).to be >= seed_config.dig('patients', 'count')
      expect(BloodPressure.count).to be >= seed_config.dig('patients', 'blood_pressures')
      expect(Appointment.count).to be >= seed_config.dig('patients', 'appointments')
    end

    it 'has overdue appointments is specified' do
      expect(Appointment.overdue.count).to be >= 1
    end

    context 'overdue', if: :overdue do
      it 'has overdue appointments' do
        expect(Appointment.overdue.count).to be >= 1
      end
    end

    context 'not overdue', if: !:overdue do
      it 'has overdue appointments' do
        expect(Appointment.overdue.count).to eq 0
      end
    end

    context 'hypertensive', if: :hypertensive do
      it 'has hypertensive patients' do
        expect(BloodPressure.hypertensive.count).to be >= 1
      end
    end

    context 'hypertensive', if: !:hypertensive do
      it 'has hypertensive patients' do
        expect(BloodPressure.hypertensive.count).to eq 0
      end
    end
  end
end

