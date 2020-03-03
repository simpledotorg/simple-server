require File.expand_path('../../../config/environment', __dir__)
require 'csv'
require 'pry'

############################
# Convert CSV to easily readable row-based format
############################
from = ARGV.shift
facility_name = ARGV.shift
DISTRICT = ARGV.shift

encrypted_message = open(from).read
key = ActiveSupport::KeyGenerator.new(ENV['BD_IMPORT_KEY']).generate_key(ENV['BD_IMPORT_SALT'], 32)
crypt = ActiveSupport::MessageEncryptor.new(key)
message = crypt.decrypt_and_verify(encrypted_message)
data = CSV.parse(message, headers: true)

BUSINESS_IDENTIFIER_METADATA_VERSION = "org.simple.bangladesh_national_id.meta.v1"

ERR_LOG_TAG = '[RECORD_IMPORT_ERR]'

patient_data = []

(0...data.length).each do |row|
  patient_data << ['patient_key', row]
  data[row].headers.each_with_index do |header, index|
    value = data[row][index]
    patient_data << [header, value] if value
  end
end

############################
# Read rows one-by-one to assemble and persist patients
############################
patients = {}
patient_key = nil
blood_pressure = {}
visit_medications = {}
patient_medications = {}

$registration_facility = Facility.find_by(name: facility_name)
$registration_user = User.create_with(
  sync_approval_status: 'denied',
  sync_approval_status_reason: 'User is a robot',
  device_created_at: DateTime.current,
  device_updated_at: DateTime.current
).find_or_create_by!(full_name: "#{DISTRICT.downcase}-import-user")

unless $registration_user.phone_number_authentications.any?
  phone_number_authentication = PhoneNumberAuthentication.new(
    user: $registration_user,
    facility: $registration_facility,
    password: rand(1000..9999).to_s,
    phone_number: rand(1000..9999).to_s
  )

  phone_number_authentication.set_otp
  phone_number_authentication.set_access_token

  phone_number_authentication.save!
end

def report_failure(reason, params)
  puts "#{ERR_LOG_TAG} ex_id: #{params[:external_id]} - Patient failed: #{reason}"
end

def report_success(params)
  puts "ex_id: #{params[:external_id]} - Patient created"
end

def patient_gender(gender)
  if ['m', 'M', 'male', 'Male', 'MALE'].include?(gender)
    'male'
  elsif ['f', 'F', 'female', 'Female', 'FEMALE'].include?(gender)
    'female'
  end
end

def national_id(value)
  # scientific notation
  if /e\+/.match?(value)
    base, exp = value.split("e+").map(&:to_i)
    (base * exp**10).to_i.to_s
  else
    value
  end
end

def history(value)
  return 'yes' if value.to_i == 1

  'unknown'
end

def dosage(value)
  dosage_value = value.scan(/(\d|\.)/).join.to_f
  if dosage_value.to_i == dosage_value
    "#{dosage_value.to_i} mg" # 50.0 -> "50 mg"
  else
    "#{dosage_value} mg" # 12.5 -> "12.5 mg"
  end
end

def patient_recorded_at(blood_pressures)
  date = blood_pressures.map { |bp| bp[:recorded_at] }.min
  return DateTime.new(2019, 6, 1) if date.nil?
  date
end

def create_patient(params)
  if params[:gender].blank?
    report_failure("unknown gender", params)
    return
  end

  if params[:full_name].blank?
    report_failure("missing name", params)
    return
  end

  if params[:age].blank? && params[:date_of_birth].blank?
    report_failure("missing age", params)
    return
  end

  Patient.transaction do
    now = DateTime.current

    address = Address.create!(
      id: SecureRandom.uuid,
      **params[:address],
      district: DISTRICT,
      state: 'Sylhet',
      country: 'Bangladesh',
      device_created_at: now,
      device_updated_at: now
    )

    patient = Patient.create!(
      id: SecureRandom.uuid,
      full_name: params[:full_name],
      gender: params[:gender],
      age: params[:age],
      date_of_birth: params[:date_of_birth],
      age_updated_at: (now if params[:age].present?),
      registration_facility: $registration_facility,
      registration_user: $registration_user,
      address: address,
      status: 'active',
      recorded_at: patient_recorded_at(params[:blood_pressures]),
      device_created_at: now,
      device_updated_at: now
    )

    PatientBusinessIdentifier.create!(
      identifier_type: 'bangladesh_national_id',
      identifier: params[:business_identifier],
      patient: patient,
      device_created_at: now,
      device_updated_at: now,
      "metadata_version": "org.simple.bangladesh_national_id.meta.v1",
      "metadata": { assigningFacilityUuid: $registration_facility.id, assigningUserUuid: $registration_user.id }.to_json
    ) unless params[:business_identifier].blank?

    if params[:phone_number].present?
      PatientPhoneNumber.create!(
        id: SecureRandom.uuid,
        patient: patient,
        number: params[:phone_number],
        phone_type: 'mobile',
        active: true,
        device_created_at: now,
        device_updated_at: now
      )
    end

    MedicalHistory.create!(
      id: SecureRandom.uuid,
      patient: patient,
      user: $registration_user,
      diagnosed_with_hypertension: 'yes',
      receiving_treatment_for_hypertension: 'yes',
      hypertension: 'yes',
      **params[:medical_history],
      device_created_at: now,
      device_updated_at: now
    )

    params[:blood_pressures].each do |bp|
      encountered_on = Encounter.generate_encountered_on(bp[:recorded_at], 21_600)
      encounter = Encounter.create_with(
        patient: patient,
        facility: $registration_facility,
        encountered_on: encountered_on,
        timezone_offset: 21_600,
        device_created_at: now,
        device_updated_at: now
      ).find_or_create_by!(
        id: Encounter.generate_id($registration_facility.id, patient.id, encountered_on)
      )

      blood_pressure = BloodPressure.create!(
        id: SecureRandom.uuid,
        systolic: bp[:systolic],
        diastolic: bp[:diastolic],
        recorded_at: bp[:recorded_at],
        patient: patient,
        user: $registration_user,
        facility: $registration_facility,
        device_created_at: now,
        device_updated_at: now
      )

      Observation.create!(
        encounter: encounter,
        observable: blood_pressure,
        user: $registration_user
      )
    end

    params[:prescription_drugs].each do |name, dosage|
      # Default dosage if only one
      if !dosage && ProtocolDrug.where(name: name).count == 1
        dosage = ProtocolDrug.find_by(name: name).dosage
      end

      is_protocol_drug = ProtocolDrug.exists?(name: name, dosage: dosage)

      PrescriptionDrug.create!(
        id: SecureRandom.uuid,
        name: name,
        dosage: dosage,
        rxnorm_code: '',
        is_protocol_drug: is_protocol_drug,
        is_deleted: false,
        patient: patient,
        user: $registration_user,
        facility: $registration_facility,
        device_created_at: now,
        device_updated_at: now
      )
    end

    puts "Creating patient: #{params[:business_identifier]}"

    if latest_blood_pressure = patient.reload.latest_blood_pressure
      Appointment.create!(
        status: 'scheduled',
        appointment_type: 'automatic',
        scheduled_date: latest_blood_pressure.recorded_at + 1.month,
        patient: patient,
        facility: $registration_facility,
        creation_facility_id: $registration_facility.id,
        user: $registration_user,
        device_created_at: now,
        device_updated_at: now
      )
    end

    report_success(params)
  end
end

patient_data.each_with_index do |row, index|
  key = row[0]
  value = row[1]

  if key == 'patient_key'
    # Save previous patient before starting the next
    if patient_key
      patient_medications = visit_medications
      patients[patient_key][:prescription_drugs] = patient_medications
      patient_medications = {}
      visit_medications = {}

      create_patient(patients[patient_key]) if patients[patient_key][:full_name]
    end

    patient_key = value
    patients[patient_key] ||= {
      blood_pressures: [],
      address: {},
      medical_history: {
        chronic_kidney_disease: "unknown",
        diabetes: "unknown",
        diagnosed_with_hypertension: "unknown",
        hypertension: "unknown",
        prior_heart_attack: "unknown",
        prior_stroke: "unknown",
        receiving_treatment_for_hypertension: "unknown"
      },
      prescription_drugs: {}
    }
  end

  # Patient info
  patients[patient_key][:external_id] = value if key == 'Pt Unique ID'
  patients[patient_key][:full_name] = value if key == 'Name of Patient'
  patients[patient_key][:gender] = patient_gender(value) if key == 'Sex'
  patients[patient_key][:age] = value if key == 'Age (years)'
  if key == 'Date of Birth'
    patients[patient_key][:date_of_birth] = begin
      date = DateTime.parse(value)
      date = DateTime.parse(blood_pressure[:recorded_at])
      date > DateTime.now ? nil : date
    rescue ArgumentError
      nil
    rescue TypeError
      nil
    end
  end
  patients[patient_key][:business_identifier] = national_id(value) if key == 'NID'
  patients[patient_key][:phone_number] = value if key == 'Mobile Number (patient)'

  # Medical History
  patients[patient_key][:medical_history][:prior_heart_attack] = history(value) if key == 'Past History of Heart Attack'
  patients[patient_key][:medical_history][:prior_stroke] = history(value) if key == 'Past History of Brain Stroke'
  patients[patient_key][:medical_history][:diabetes] = history(value) if key == 'Past History Of Diabaties'

  if key == 'Past History of Chronic Kidney Disease'
    patients[patient_key][:medical_history][:chronic_kidney_disease] = history(value)
  end

  # Address
  patients[patient_key][:address][:street_address] = value if key == 'Address'
  patients[patient_key][:address][:village_or_colony] = value if key == 'Village'
  patients[patient_key][:address][:pin] = value if key == 'Post Code'
  patients[patient_key][:address][:zone] = value if key == 'Union/Pouroshava'

  # BP Reading
  if /SBP/.match?(key)
    patient_medications = visit_medications
    visit_medications = {}

    date = patient_data[index - 1][1]

    blood_pressure[:systolic] = value.to_i
    blood_pressure[:recorded_at] = date
  end

  if /DBP/.match?(key)
    blood_pressure[:diastolic] = value.to_i

    patients[patient_key][:blood_pressures].push(
      systolic: blood_pressure[:systolic],
      diastolic: blood_pressure[:diastolic],
      recorded_at: begin
                     date = DateTime.parse(blood_pressure[:recorded_at])
                     date > DateTime.now ? DateTime.new(2019, 6, 1) : date
                   rescue ArgumentError
                     DateTime.new(2019, 6, 1)
                   rescue TypeError
                     DateTime.new(2019, 6, 1)
                   end
    )
  end

  # Medications
  visit_medications['Amlodipine'] = dosage(value) if /^Amlodipine/.match?(key)
  visit_medications['Losartan Potassium'] = dosage(value) if /^Losartan/.match?(key) || /^Losrtan/.match?(key)
  visit_medications['Hydrochlorothiazide'] = dosage(value) if /^Hydrocholothiazide/.match?(key)
  visit_medications['Atenolol'] = dosage(value) if /^Beta Blocker/.match?(key)
  visit_medications['Aspirin'] = dosage(value) if /^Aspirin/.match?(key)
  visit_medications['Rosuvastatin'] = dosage(value) if /^Statin/.match?(key)
  visit_medications[value] = dosage(value) if /^Other/.match?(key)
  visit_medications[value] = dosage(value) if /^Other 2/.match?(key)
  visit_medications[value] = dosage(value) if /^Other 2-1/.match?(key)
  visit_medications[value] = dosage(value) if /^Other 2-2/.match?(key)
  visit_medications[value] = dosage(value) if /^Other 2-3/.match?(key)
  visit_medications[value] = dosage(value) if /^Other 2-4/.match?(key)
end
