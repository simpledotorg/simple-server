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

      strategy DataAnon::Strategy::Whitelist
      source_db source_db_config
      destination_db destination_db_config

      table 'organizations' do
        primary_key 'id'
        whitelist 'name'
        whitelist 'description'
        whitelist_timestamps
      end

      table 'facility_groups' do
        primary_key 'id'
        whitelist 'name'
        whitelist 'description'
        whitelist 'organization_id'
        whitelist 'protocol_id'
        whitelist_timestamps
      end

      table 'facilities' do
        primary_key 'id'
        whitelist 'country', 'facility_type'
        whitelist 'facility_group_id'
        scramble('facilities', 'name')
        scramble('facilities', 'district')
        scramble('facilities', 'state')
        scramble('facilities', 'street_address')
        scramble('facilities', 'village_or_colony')
        scramble('facilities', 'pin')
        scramble('facilities', 'created_at')
        scramble('facilities', 'updated_at')
        scramble('facilities', 'latitude')
        scramble('facilities', 'longitude')
        whitelist_timestamps
      end

      table 'protocols' do
        primary_key 'id'
        scramble('protocols', 'name')
        scramble('protocols', 'follow_up_days')
        whitelist_timestamps
      end

      table 'protocol_drugs' do
        primary_key 'id'
        whitelist 'protocol_id'
        scramble('protocol_drugs', 'name')
        scramble('protocol_drugs', 'dosage')
        scramble('protocol_drugs', 'rxnorm_code')
        whitelist_timestamps
      end

      table 'admins' do
        primary_key 'id'
        whitelist 'email'
        whitelist 'encrypted_password'
        nullify 'last_sign_in_ip'
        nullify 'current_sign_in_ip'
        whitelist 'invitations_count'
        whitelist 'invited_by_id'
        whitelist 'invited_by_type'
        whitelist 'role'
        whitelist 'sign_in_count'
        whitelist 'current_sign_in_at'
        whitelist 'last_sign_in_at'
        whitelist 'failed_attempts'
        whitelist 'invitation_created_at'
        whitelist 'invitation_sent_at'
        whitelist 'invitation_accepted_at'
        whitelist 'invitation_token'
        whitelist 'remember_created_at'
        whitelist 'reset_password_token'
        whitelist 'reset_password_sent_at'
        whitelist_timestamps
      end

      table 'admin_access_controls' do
        primary_key 'id'
        whitelist 'admin_id'
        whitelist 'access_controllable_type'
        whitelist 'access_controllable_id'
        whitelist_timestamps
      end

      table 'users' do
        primary_key 'id'
        whitelist 'sync_approval_status'
        anonymize('full_name').using FieldStrategy::RandomFullName.new
        anonymize('phone_number').using FieldStrategy::FormattedStringNumber.new
        anonymize('password_digest').using FieldStrategy::RandomFormattedString.new
        scramble('users', 'otp')
        scramble('users', 'otp_valid_until')
        scramble('users', 'access_token')
        scramble('users', 'logged_in_at')
        whitelist 'registration_facility_id'
        whitelist 'sync_approval_status_reason'
        whitelist_timestamps
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
        whitelist 'patient_id', 'phone_type', 'active'
        whitelist_timestamps
        anonymize('number').using FieldStrategy::FormattedStringNumber.new
        anonymize('phone_type').using FieldStrategy::SelectFromList.new(%w[mobile landline].freeze)
        whitelist 'active'
        whitelist_timestamps
      end

      table 'blood_pressures' do
        primary_key 'id'
        whitelist 'user_id', 'facility_id', 'patient_id'
        whitelist 'systolic', 'diastolic'
        whitelist_timestamps
      end

      table 'prescription_drugs' do
        primary_key 'id'
        whitelist 'facility_id', 'patient_id', 'name', 'rxnorm_code', 'dosage'
        whitelist 'is_protocol_drug', 'is_deleted'
        whitelist_timestamps
      end

      table 'appointments' do
        primary_key 'id'
        whitelist 'facility_id'
        whitelist 'patient_id'
        whitelist 'status'
        whitelist 'cancel_reason'
        scramble('appointments', 'scheduled_date')
        scramble('appointments', 'remind_on')
        scramble('appointments', 'agreed_to_visit')
        whitelist_timestamps
      end

      table 'medical_histories' do
        primary_key 'id'
        whitelist 'patient_id'
        scramble('medical_histories', 'device_created_at')
        scramble('medical_histories', 'device_created_at')
        scramble('medical_histories', 'device_updated_at')
        scramble('medical_histories', 'created_at')
        scramble('medical_histories', 'updated_at')
        scramble('medical_histories', 'prior_heart_attack')
        scramble('medical_histories', 'prior_stroke')
        scramble('medical_histories', 'chronic_kidney_disease')
        scramble('medical_histories', 'receiving_treatment_for_hypertension')
        scramble('medical_histories', 'diabetes')
        scramble('medical_histories', 'diagnosed_with_hypertension')
        scramble('medical_histories', 'prior_heart_attack_boolean')
        scramble('medical_histories', 'prior_stroke_boolean')
        scramble('medical_histories', 'chronic_kidney_disease_boolean')
        scramble('medical_histories', 'receiving_treatment_for_hypertension_boolean')
        scramble('medical_histories', 'diabetes_boolean')
        scramble('medical_histories', 'diagnosed_with_hypertension_boolean')
        whitelist_timestamps
      end

      table 'communications' do
        primary_key 'id'
        whitelist 'appointment_id'
        whitelist 'user_id'
      end
    end
  end
end