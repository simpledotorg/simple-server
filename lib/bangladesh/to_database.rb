require File.expand_path('../../../config/boot',  __FILE__)
require 'csv'
require 'yaml'

from = File.expand_path('../data/patients.csv',  __FILE__)

data = CSV.parse(File.open(from))

patients = {}
patient_key = nil
blood_pressure = {}

def history(value)
  case value.to_i
  when 0
    "unknown"
  when 1
    "yes"
  end
end

data.each_with_index do |row, index|
  key = row[0]
  value = row[1]

  if key == 'patient_key'
    patient_key = value
    patients[patient_key] ||= {
      blood_pressures: [],
      phone_numbers: [],
      business_identifiers: [],
      address: {},
      medical_history: {}
    }

    puts "Patients so far"
    puts "---------------"
    puts YAML.dump(patients)

    puts "Press enter to continue"
    gets.chomp
  end


  patients[patient_key][:full_name] = value                if key == 'Name of Patient'
  patients[patient_key][:gender] = value                   if key == 'Sex'
  patients[patient_key][:age] = value                      if key == 'Age (years)'
  patients[patient_key][:date_of_birth] = value            if key == 'Date of Birth'
  patients[patient_key][:full_name] = value                if key == 'Name of Patient'
  patients[patient_key][:business_identifiers].push(value) if key == 'NID'
  patients[patient_key][:phone_numbers].push(value)        if key == 'Mobile Number (patient)'

  patients[patient_key][:medical_history][:prior_heart_attack] = history(value)     if key == 'Past History of Heart Attack'
  patients[patient_key][:medical_history][:prior_stroke] = history(value)           if key == 'Past History of Brain Stroke'
  patients[patient_key][:medical_history][:chronic_kidney_disease] = history(value) if key == 'Past History of Chronic Kidney Disease'
  patients[patient_key][:medical_history][:diabetes] = history(value)               if key == 'Past History Of Diabaties'

  if key =~ /SBP/
    date = data[index - 1][1]

    blood_pressure[:systolic] = value.to_i
    blood_pressure[:recorded_at] = date
  end

  if key =~ /DBP/
    blood_pressure[:diastolic] = value.to_i

    patients[patient_key][:blood_pressures].push(
      systolic: blood_pressure[:systolic],
      diastolic: blood_pressure[:diastolic],
      recorded_at: blood_pressure[:recorded_at]
    )
  end
end
