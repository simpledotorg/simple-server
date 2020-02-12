require File.expand_path('../../config/environment', __dir__)
require 'csv'
require 'pry'

############################
# Convert CSV to easily readable row-based format
############################
from = ARGV.shift
facility_name = ARGV.shift
district = ARGV.shift

encrypted_message = open(from).read
key = ActiveSupport::KeyGenerator.new(ENV['BD_IMPORT_KEY']).generate_key(ENV['BD_IMPORT_SALT'], 32)
crypt = ActiveSupport::MessageEncryptor.new(key)
message = crypt.decrypt_and_verify(encrypted_message)
data = CSV.parse(message, headers: true)

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
).find_or_create_by!(full_name: 'bangladesh-import-user')

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
  case value.to_i
  when 0
    'unknown'
  when 1
    'yes'
  end
end

def dosage(value)
  dosage_value = value.scan(/(\d|\.)/).join.to_f
  if dosage_value.to_i == dosage_value
    "#{dosage_value.to_i} mg"     # 50.0 -> "50 mg"
  else
    "#{dosage_value} mg"          # 12.5 -> "12.5 mg"
  end
end

def create_patient(params)
  Patient.transaction do
    now = DateTime.current

    address = Address.create!(
      id: SecureRandom.uuid,
      **params[:address],
      district: district,
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
      registration_facility: $registration_facility,
      registration_user: $registration_user,
      address: address,
      recorded_at: params[:blood_pressures].map { |bp| bp[:recorded_at] }.min,
      device_created_at: now,
      device_updated_at: now
    )

    PatientBusinessIdentifier.create!(
      identifier_type: 'bangladesh_national_id',
      identifier: params[:business_identifier],
      patient: patient,
      device_created_at: now,
      device_updated_at: now
    ) unless params[:business_identifier].blank?

    PatientPhoneNumber.create!(
      id: SecureRandom.uuid,
      patient: patient,
      number: params[:phone_number],
      phone_type: 'mobile',
      device_created_at: now,
      device_updated_at: now
    )

    MedicalHistory.create!(
      id: SecureRandom.uuid,
      patient: patient,
      user: $registration_user,
      diagnosed_with_hypertension: 'yes',
      hypertension: 'yes',
      **params[:medical_history],
      device_created_at: now,
      device_updated_at: now
    )

    params[:blood_pressures].each do |bp|
      encounter = Encounter.create!(
        patient: patient,
        facility: $registration_facility,
        encountered_on: bp[:recorded_at],
        timezone_offset: 21_600,
        device_created_at: now,
        device_updated_at: now
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
      medical_history: {},
      prescription_drugs: {}
    }
  end

  # Patient info
  patients[patient_key][:full_name] = value                        if key == 'Name of Patient'
  patients[patient_key][:gender] = value                           if key == 'Sex'
  patients[patient_key][:age] = value                              if key == 'Age (years)'
  patients[patient_key][:date_of_birth] = value                    if key == 'Date of Birth'
  patients[patient_key][:business_identifier] = national_id(value) if key == 'NID'
  patients[patient_key][:phone_number] = value                     if key == 'Mobile Number (patient)'

  # Medical History
  patients[patient_key][:medical_history][:prior_heart_attack] = history(value) if key == 'Past History of Heart Attack'
  patients[patient_key][:medical_history][:prior_stroke] = history(value)       if key == 'Past History of Brain Stroke'
  patients[patient_key][:medical_history][:diabetes] = history(value)           if key == 'Past History Of Diabaties'
  if key == 'Past History of Chronic Kidney Disease'
    patients[patient_key][:medical_history][:chronic_kidney_disease] = history(value)
  end

  # Address
  patients[patient_key][:address][:street_address]    = value  if key == 'Address'
  patients[patient_key][:address][:village_or_colony] = value  if key == 'Village'
  patients[patient_key][:address][:pin] = value                if key == 'Post Code'
  patients[patient_key][:address][:zone] = value               if key == 'Union/Pouroshava'

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
        DateTime.parse(blood_pressure[:recorded_at])
      rescue ArgumentError
        DateTime.new(2019, 6, 1)
      rescue TypeError
        DateTime.new(2019, 6, 1)
      end
    )
  end

  # Medications
  visit_medications['Amlodipine'] = dosage(value)          if /^Amlodipine/.match?(key)
  visit_medications['Losartan Potassium'] = dosage(value)  if /^Losartan/.match?(key) || /^Losrtan/.match?(key)
  visit_medications['Hydrochlorothiazide'] = dosage(value) if /^Hydrocholothiazide/.match?(key)
  visit_medications['Atenolol'] = dosage(value)            if /^Beta Blocker/.match?(key)
  visit_medications['Aspirin'] = dosage(value)             if /^Aspirin/.match?(key)
  visit_medications['Rosuvastatin'] = dosage(value)        if /^Statin/.match?(key)
  visit_medications[value] = dosage(value)                 if /^Other/.match?(key)
  visit_medications[value] = dosage(value)                 if /^Other 2/.match?(key)
  visit_medications[value] = dosage(value)                 if /^Other 2-1/.match?(key)
  visit_medications[value] = dosage(value)                 if /^Other 2-2/.match?(key)
  visit_medications[value] = dosage(value)                 if /^Other 2-3/.match?(key)
  visit_medications[value] = dosage(value)                 if /^Other 2-4/.match?(key)
end
