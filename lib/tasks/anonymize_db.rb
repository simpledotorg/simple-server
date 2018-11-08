require 'data-anonymization'

DataAnon::Utils::Logging.logger.level = Logger::INFO

def source_db_config
  { :adapter => 'postgresql',
    :host => 'localhost',
    :database => 'simple-server_development' }
end

def destination_db_config
  { :adapter => 'postgresql',
    :host => 'localhost',
    :database => 'simple-server_test' }
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

database 'SimpleServerDatabase' do

  strategy DataAnon::Strategy::Whitelist
  source_db source_db_config
  destination_db destination_db_config

  table 'facilities' do
    primary_key 'id'
    whitelist 'country', 'facility_type'
    scramble('facilities', 'name')
    scramble('facilities', 'district')
    scramble('facilities', 'state')
  end

  table 'protocols' do
    primary_key 'id'
    scramble('protocols', 'name')
  end

  table 'protocol_drugs' do
    primary_key 'id'
  end

  table 'admins' do
    primary_key 'id'
    nullify 'last_sign_in_ip'
    nullify 'current_sign_in_ip'
    whitelist 'invitations_count'
    whitelist 'invited_by_id'
    whitelist 'invited_by_type'
    whitelist 'role'
  end

  table 'users' do
    primary_key 'id'
    whitelist 'sync_approval_status'
    anonymize('full_name').using FieldStrategy::RandomFullName.new
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
    whitelist 'full_name', 'age', 'gender', 'status', 'address_id', 'date_of_birth'
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
  end

  table 'user_facilities' do
    primary_key 'id'
    whitelist 'facility_id'
    whitelist 'user_id'
  end

  table 'medical_histories' do
    primary_key 'id'
    whitelist 'patient_id'
  end

  table 'communications' do
    primary_key 'id'
    whitelist 'appointment_id'
    whitelist 'user_id'
  end
end

