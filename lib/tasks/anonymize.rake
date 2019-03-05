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

def hashed_uuid(uuid)
  UUIDTools::UUID.md5_create(UUIDTools::UUID_DNS_NAMESPACE, { uuid: uuid }.to_s).to_s
end

def anonymize_uuid(column)
  anonymize(column) do |field|
    hashed_uuid(field.value)
  end
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
        whitelist 'name'
        whitelist 'district'
        whitelist 'state'
        whitelist 'street_address'
        whitelist 'village_or_colony'
        whitelist 'pin'
        whitelist 'created_at'
        whitelist 'updated_at'
        whitelist 'latitude'
        whitelist 'longitude'
        whitelist_timestamps
      end

      table 'protocols' do
        primary_key 'id'
        whitelist 'name'
        whitelist 'follow_up_days'
        whitelist_timestamps
      end

      table 'protocol_drugs' do
        primary_key 'id'
        whitelist 'protocol_id'
        whitelist 'name'
        whitelist 'dosage'
        whitelist 'rxnorm_code'
        whitelist_timestamps
      end

      table 'admins' do
        primary_key 'id'
        whitelist 'email'
        whitelist 'encrypted_password'
        whitelist 'role'
        nullify 'last_sign_in_ip'
        nullify 'current_sign_in_ip'
        whitelist 'invitations_count'
        whitelist 'invited_by_id'
        whitelist 'invited_by_type'
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

      table 'addresses' do
        anonymize_uuid 'id'
        scramble('addresses', 'street_address')
        scramble('addresses', 'village_or_colony')
        scramble('addresses', 'district')
        scramble('addresses', 'state')
        scramble('addresses', 'country')
        scramble('addresses', 'pin')
        whitelist_timestamps
      end

      table 'patients' do
        anonymize_uuid 'id'
        scramble('patients', 'full_name')
        scramble('patients', 'age')
        scramble('patients', 'gender')
        scramble('patients', 'status')
        scramble('patients', 'date_of_birth')
        scramble('patients', 'age_updated_at')
        whitelist 'registration_user_id'
        anonymize_uuid 'address_id'
        whitelist 'test_data'
        whitelist 'registration_facility_id'
        whitelist_timestamps
      end

      table 'patient_phone_numbers' do
        primary_key 'id'
        anonymize_uuid 'patient_id'
        whitelist 'phone_type', 'active'
        whitelist_timestamps
        anonymize('number').using FieldStrategy::FormattedStringNumber.new
        anonymize('phone_type').using FieldStrategy::SelectFromList.new(%w[mobile landline].freeze)
        whitelist 'active'
        whitelist_timestamps
      end

      table 'blood_pressures' do
        anonymize_uuid 'id'
        whitelist 'user_id', 'facility_id'
        anonymize_uuid 'patient_id'
        whitelist 'systolic', 'diastolic'
        whitelist_timestamps
      end

      table 'prescription_drugs' do
        anonymize_uuid 'id'
        whitelist 'facility_id', 'name', 'rxnorm_code', 'dosage'
        anonymize_uuid 'patient_id'
        whitelist 'is_protocol_drug', 'is_deleted'
        whitelist_timestamps
      end

      table 'appointments' do
        anonymize_uuid 'id'
        whitelist 'facility_id'
        anonymize_uuid 'patient_id'
        whitelist 'cancel_reason'
        whitelist 'scheduled_date'
        whitelist 'status'
        whitelist 'remind_on'
        whitelist 'agreed_to_visit'
        whitelist_timestamps
      end

      table 'medical_histories' do
        primary_key 'id'
        anonymize_uuid 'patient_id'
        whitelist 'device_created_at'
        whitelist 'device_updated_at'
        whitelist 'created_at'
        whitelist 'updated_at'
        whitelist 'prior_heart_attack'
        whitelist 'prior_stroke'
        whitelist 'chronic_kidney_disease'
        whitelist 'receiving_treatment_for_hypertension'
        whitelist 'diabetes'
        whitelist 'diagnosed_with_hypertension'
        whitelist 'prior_heart_attack_boolean'
        whitelist 'prior_stroke_boolean'
        whitelist 'chronic_kidney_disease_boolean'
        whitelist 'receiving_treatment_for_hypertension_boolean'
        whitelist 'diabetes_boolean'
        whitelist 'diagnosed_with_hypertension_boolean'
        whitelist_timestamps
      end

      table 'communications' do
        primary_key 'id'
        anonymize_uuid 'appointment_id'
        whitelist 'user_id'
      end
    end
  end

  desc 'Anonymize production users into application database'
  task :users do
    database 'SimpleServerDatabase' do

      strategy DataAnon::Strategy::Whitelist
      source_db source_db_config
      destination_db destination_db_config

      table 'users' do
        primary_key 'id'
        anonymize('full_name').using FieldStrategy::RandomFullName.new
        anonymize('phone_number').using FieldStrategy::FormattedStringNumber.new
        anonymize('password_digest').using FieldStrategy::RandomString.new
        whitelist 'device_created_at'
        whitelist 'device_updated_at'
        whitelist 'created_at'
        whitelist 'updated_at'
        whitelist 'otp'
        whitelist 'otp_valid_until'
        anonymize('access_token').using FieldStrategy::RandomString.new
        whitelist 'logged_in_at'
        whitelist 'sync_approval_status'
        whitelist 'sync_approval_status_reason'
        whitelist 'deleted_at'
        whitelist 'registration_facility_id'
      end
    end
  end

  desc 'Anonymize audit logs into application database'
  task :audit_logs do
    database 'SimpleServerDatabase' do

      strategy DataAnon::Strategy::Whitelist
      source_db source_db_config
      destination_db destination_db_config

      MODELS_WITH_ANONYMIZED_PRIMARY_KEYS = %w[
        Patient
        Address
        BloodPressure
        PrescriptionDrug
        Appointment
      ]

      table 'audit_logs' do
        primary_key 'id'
        whitelist 'action'
        whitelist 'auditable_type'
        anonymize('auditable_id') do |field|
          if (MODELS_WITH_ANONYMIZED_PRIMARY_KEYS.include?(field.ar_record.auditable_type))
            hashed_uuid(field.value)
          else
            field.value
          end
        end
        whitelist 'updated_at'
        whitelist 'created_at'
        whitelist 'user_id'
      end
    end
  end
end
