require 'data-anonymization'

DataAnon::Utils::Logging.logger.level = Logger::INFO

def source_db_config
  { adapter: 'postgresql',
    encoding: 'unicode',
    pool: ENV.fetch('RAILS_MAX_THREADS') { 5 },
    host: ENV.fetch('DATABASE_WITH_PHI_HOST'),
    username: ENV.fetch('DATABASE_WITH_PHI_USERNAME'),
    password: ENV.fetch('DATABASE_WITH_PHI_PASSWORD'),
    database: ENV.fetch('DATABASE_WITH_PHI_DATABASE') }
end

def destination_db_config
  Rails.configuration.database_configuration[Rails.env]
end

def scramble(table, column)
  anonymize(column).using FieldStrategy::SelectFromDatabase.new(table, column, source_db_config)
end

def nullify(column)
  anonymize(column) { |_field| nil }
end

def whitelist_timestamps
  whitelist 'device_created_at', 'device_updated_at', 'created_at', 'updated_at'
end

namespace :anonymize do
  desc 'Anonymize production database into application database;
        Example: rake "anonymize:full_database"'
  task :full_database do

    database 'SimpleServerDatabase' do

      strategy DataAnon::Strategy::Blacklist
      source_db source_db_config
      destination_db destination_db_config

      table 'organizations' do
        primary_key 'id'
      end

      table 'facility_groups' do
        primary_key 'id'
      end

      table 'facilities' do
        primary_key 'id'
      end

      table 'protocols' do
        primary_key 'id'
      end

      table 'protocol_drugs' do
        primary_key 'id'
      end

      table 'admins' do
        primary_key 'id'
      end

      table 'admin_access_controls' do
        primary_key 'id'
      end

      table 'addresses' do
        primary_key 'id'
        scramble('addresses', 'street_address')
        scramble('addresses', 'village_or_colony')
        scramble('addresses', 'district')
        scramble('addresses', 'state')
        scramble('addresses', 'country')
        scramble('addresses', 'pin')
        whitelist_timestamps
      end

      table 'patients' do
        primary_key 'id'
        scramble('patients', 'full_name')
        scramble('patients', 'age')
        scramble('patients', 'gender')
        scramble('patients', 'status')
        scramble('patients', 'address_id')
        scramble('patients', 'date_of_birth')
        scramble('patients', 'age_updated_at')
        whitelist 'test_data'
        whitelist 'registration_user_id'
        whitelist 'registration_facility_id'
        whitelist_timestamps
      end

      table 'patient_phone_numbers' do
        primary_key 'id'
        anonymize('number').using FieldStrategy::FormattedStringNumber.new
        anonymize('phone_type').using FieldStrategy::SelectFromList.new(%w[mobile landline].freeze)
      end

      table 'blood_pressures' do
        primary_key 'id'
      end

      table 'prescription_drugs' do
        primary_key 'id'
      end

      table 'appointments' do
        primary_key 'id'
      end

      table 'medical_histories' do
        primary_key 'id'
      end

      table 'communications' do
        primary_key 'id'
      end
    end
  end
end