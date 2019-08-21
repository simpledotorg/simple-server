number_of_months = ENV.fetch("NUMBER_OF_MONTHS") { 12 }.to_i

module SeedConstants
  NUMBER_OF_ORGANIZATIONS = rand(2..5)
  NUMBER_OF_PROTOCOLS = 3
  FACILITY_GROUPS_PER_ORGANIZATION = rand(2..5)
  FACILITIES_PER_FACILITY_GROUP = rand(2..5)
  USERS_PER_FACILITY = rand(2..5)
  NUMBER_OF_PATIENTS = rand(5..10)
  MEDICAL_HISTORIES_PER_PATIENT = 3
  PRESCRIPTION_DRUGS_PER_PATIENT = 3
  BLOOD_PRESSURES_PER_PATIENT = rand(10..15)
  APPOINTMENTS_PER_PATIENT = rand(5..10)
end

def create_protocols
  puts "Creating protocols"

  protocol = FactoryBot.create(:protocol)

  SeedConstants::NUMBER_OF_PROTOCOLS.times do
    FactoryBot.create(:protocol_drug, protocol: protocol)
  end
end

def create_organization(creation_date)
  puts "Creating organizations for #{creation_date}"

  organization = FactoryBot.create(:organization, created_at: creation_date, updated_at: creation_date)
  create_facility_groups(organization, creation_date)
  organization
end

def create_organization_patient_records(organization, date)
  facility_groups = organization.facility_groups

  facility_groups.flat_map(&:facilities).flat_map(&:registered_patients).each do |patient|
    create_blood_pressures(patient, date) if Random.rand(1..10) < 8
  end

  facility_groups.flat_map(&:users).each do |user|
    SeedConstants::NUMBER_OF_PATIENTS.times do
      patient = FactoryBot.create(:patient, registration_facility: user.registration_facility,
                                  registration_user: user,
                                  created_at: date,
                                  updated_at: date,
                                  device_created_at: date,
                                  device_updated_at: date)
      create_medical_history(patient, date)
      create_prescription_drugs(patient, date)
      create_blood_pressures(patient, date)
      create_appointments(patient, date)
    end
  end
end

def create_facility_groups(organization, creation_date)
  puts "Creating facility groups for #{creation_date}"

  SeedConstants::FACILITY_GROUPS_PER_ORGANIZATION.times do
    facility_group = FactoryBot.create(:facility_group, organization: organization, created_at: creation_date, updated_at: creation_date)

    facilities = create_and_return_facilities(facility_group, creation_date)
    create_users(facilities, creation_date)
  end
end

def create_and_return_facilities(facility_group, creation_date)
  puts "Creating facilities for #{creation_date}"

  facilities = []

  SeedConstants::FACILITIES_PER_FACILITY_GROUP.times do
    facility = FactoryBot.create(:facility, facility_group: facility_group, created_at: creation_date, updated_at: creation_date)
    facilities << facility
  end

  facilities
end

def create_users(facilities, creation_date)
  puts "Creating users for #{creation_date}"

  facilities.each do |f|
    SeedConstants::USERS_PER_FACILITY.times do
      user = FactoryBot.create(:user, registration_facility: f, created_at: creation_date, updated_at: creation_date)
      create_patients(user, creation_date)

      FactoryBot.create(:user, :sync_requested,
                        registration_facility: f,
                        created_at: creation_date,
                        updated_at: creation_date) if rand(1..10) < 5

      FactoryBot.create(:user, :sync_denied,
                        registration_facility: f,
                        created_at: creation_date,
                        updated_at: creation_date) if rand(1..10) < 5
    end
  end
end

def create_patients(user, creation_date)
  puts "Creating patients for #{creation_date}"

  SeedConstants::NUMBER_OF_PATIENTS.times do
    patient = FactoryBot.create(:patient, registration_facility: user.registration_facility,
                                registration_user: user,
                                created_at: creation_date,
                                updated_at: creation_date,
                                device_created_at: creation_date,
                                device_updated_at: creation_date)
    create_medical_history(patient, creation_date)
    create_prescription_drugs(patient, creation_date)
    create_blood_pressures(patient, creation_date)
    create_appointments(patient, creation_date)

    if rand(1..10) == 1
      create_call_logs(patient, creation_date)
      create_exotel_phone_number_detail(patient, creation_date)
    end
  end
end

def create_medical_history(patient, creation_date)
  puts "Creating medical histories for #{creation_date}"

  SeedConstants::MEDICAL_HISTORIES_PER_PATIENT.times do
    FactoryBot.create(:medical_history, :unknown,
                      patient: patient,
                      created_at: creation_date,
                      updated_at: creation_date)

    FactoryBot.create(:medical_history, :prior_risk_history,
                      patient: patient,
                      created_at: creation_date,
                      updated_at: creation_date)
  end
end

def create_prescription_drugs(patient, creation_date)
  puts "Creating prescription drugs for #{creation_date}"

  SeedConstants::PRESCRIPTION_DRUGS_PER_PATIENT.times do
    FactoryBot.create(:prescription_drug, patient: patient,
                      facility: patient.registration_facility,
                      created_at: creation_date,
                      updated_at: creation_date)
  end
end

def create_normal_blood_pressures(creation_date, patient)
  FactoryBot.create(:blood_pressure, :under_control,
                    patient: patient,
                    facility: patient.registration_facility,
                    user: patient.registration_user,
                    created_at: creation_date,
                    updated_at: creation_date,
                    recorded_at: creation_date)
end

def create_high_blood_pressures(creation_date, patient)
  FactoryBot.create(:blood_pressure, :high,
                    patient: patient,
                    facility: patient.registration_facility,
                    user: patient.registration_user,
                    created_at: creation_date,
                    updated_at: creation_date,
                    recorded_at: creation_date)
end

def create_very_high_blood_pressures(creation_date, patient)
  FactoryBot.create(:blood_pressure, :very_high,
                    patient: patient,
                    facility: patient.registration_facility,
                    user: patient.registration_user,
                    created_at: creation_date,
                    updated_at: creation_date,
                    recorded_at: creation_date)
end

def create_critical_blood_pressures(creation_date, patient)
  FactoryBot.create(:blood_pressure, :critical,
                    patient: patient,
                    facility: patient.registration_facility,
                    user: patient.registration_user,
                    created_at: creation_date,
                    updated_at: creation_date,
                    recorded_at: creation_date)
end

def create_blood_pressures(patient, creation_date)
  puts "Creating blood pressures for #{creation_date}"

  SeedConstants::BLOOD_PRESSURES_PER_PATIENT.times do
    create_normal_blood_pressures(creation_date, patient)
    create_high_blood_pressures(creation_date, patient)
    create_very_high_blood_pressures(creation_date, patient)
    create_critical_blood_pressures(creation_date, patient)
  end
end

def create_appointments(patient, creation_date)
  puts "Creating appointments for #{creation_date}"

  SeedConstants::APPOINTMENTS_PER_PATIENT.times do
    FactoryBot.create(:appointment, patient: patient,
                      facility: patient.registration_facility,
                      created_at: creation_date,
                      updated_at: creation_date)

    FactoryBot.create(:appointment, :overdue,
                      patient: patient,
                      facility: patient.registration_facility,
                      created_at: creation_date,
                      updated_at: creation_date)
  end
end

def create_admins(organization)
  puts "Creating admins for organization #{organization.name}"

  facility_group = organization.facility_groups.first
  FactoryBot.create(:admin, :counsellor, facility_group: facility_group)
  FactoryBot.create(:admin, :analyst, facility_group: facility_group)
  FactoryBot.create(:admin, :supervisor)
  FactoryBot.create(:admin, :organization_owner, organization: organization)
end

def create_call_logs(patient, creation_date)
  puts "Creating call logs for #{creation_date}"

  caller_phone_number = patient.registration_user.phone_number_authentications.first.phone_number
  callee_phone_number = patient.phone_numbers.first.number

  Timecop.travel(creation_date) do
    FactoryBot.create(:call_log,
                      session_id: SecureRandom.uuid.remove('-'),
                      caller_phone_number: caller_phone_number,
                      callee_phone_number: callee_phone_number,
                      created_at: creation_date,
                      updated_at: creation_date,
                      duration: rand(60) + 1)
  end

  Timecop.return
end

def create_exotel_phone_number_detail(patient, creation_date)
  puts "Creating exotel phone number details for #{creation_date}"

  Timecop.travel(creation_date) do
    whitelist_status = ExotelPhoneNumberDetail.whitelist_statuses.to_a.sample.first
    FactoryBot.create(:exotel_phone_number_detail, whitelist_status: whitelist_status,
                      patient_phone_number: patient.phone_numbers.first,
                      created_at: creation_date,
                      updated_at: creation_date)
  end

  Timecop.return
end

def create_seed_data(number_of_months)
  create_protocols

  organizations = []
  SeedConstants::NUMBER_OF_ORGANIZATIONS.times do
    organization = create_organization(number_of_months.months.ago)
    create_admins(organization)

    organizations << organization
    puts
  end

  number_of_months.downto(0) do |month_number|
    creation_date = month_number.months.ago

    organizations.each do |organization|
      create_organization_patient_records(organization, creation_date)
    end
  end
end

create_seed_data(number_of_months)