require 'rails_helper'
require 'yaml'

RSpec.describe 'generate:seed:generate_data' do
  include RakeTestHelper

  let!(:env) { ENV.fetch('SIMPLE_SERVER_ENV') }
  let! (:seed_config) { YAML.load_file('config/seed.yml').fetch(env) }
  let!(:overdue) { seed_config.dig('users', 'patients', 'traits').include?('overdue') }
  let!(:hypertensive) { seed_config.dig('users', 'patients', 'traits').include?('hypertensive') }
  let!(:organizations_count) { Organization.count }
  let!(:facility_groups_count) { FacilityGroup.count }
  let!(:facilities_count) { Facility.count }

  before(:all) do
    invoke_task('generate:seed:generate_data[1]')
  end

  context 'predefined values' do
    it 'has organizations created' do
      expect(Organization.count).to be >= organizations_count
    end

    it 'has facility groups created' do
      expect(FacilityGroup.count).to be >= facility_groups_count
    end

    it 'has facilities created' do
      expect(Facility.count).to be >= facilities_count
    end


    it 'has admins created' do
      expect(Admin.count).to be >= 1
    end

  end

  context 'user-supplied values' do
    it 'generates correct protocols data' do
      expect(Protocol.count).to be >= seed_config.fetch('protocols')
    end

    it 'generates correct protocol drugs data' do
      expect(ProtocolDrug.count).to be >= seed_config.fetch('protocol_drugs')
    end

    it 'generates correct user data' do
      expect(User.count).to be >= seed_config.dig('users', 'count')
    end

    it 'generates correct patient data' do
      expect(Patient.count).to be >= seed_config.dig('users', 'patients', 'count')
      expect(BloodPressure.count).to be >= seed_config.dig('users', 'patients', 'blood_pressures')
      expect(Appointment.count).to be >= seed_config.dig('users', 'patients', 'appointments')
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

