number_of_months = ENV["NUMBER_OF_MONTHS"].to_i

def create_protocols
  puts "Creating protocols"

  protocol = FactoryBot.create(:protocol)

  3.times do
    FactoryBot.create(:protocol_drug, protocol: protocol)
  end
end

def create_organization(creation_date)
  puts "Creating organizations for #{creation_date}"

  organization = FactoryBot.create(:organization, created_at: creation_date, updated_at: creation_date)
  create_facility_groups(organization, creation_date)
  organization
end

def create_facility_groups(organization, creation_date)
  puts "Creating facility groups for #{creation_date}"

  2.times do
    facility_group = FactoryBot.create(:facility_group, organization: organization, created_at: creation_date, updated_at: creation_date)

    facilities = create_and_return_facilities(facility_group, creation_date)
    create_users(facilities, creation_date)
  end
end

def create_and_return_facilities(facility_group, creation_date)
  puts "Creating facilities for #{creation_date}"

  facilities = []

  2.times do
    facility = FactoryBot.create(:facility, facility_group: facility_group, created_at: creation_date, updated_at: creation_date)
    facilities << facility
  end

  facilities
end

def create_users(facilities, creation_date)
  puts "Creating users for #{creation_date}"

  facilities.each do |f|
    2.times do
      user = FactoryBot.create(:user, registration_facility: f, created_at: creation_date, updated_at: creation_date)
      create_patients(user, creation_date)
    end
  end
end

def create_patients(user, creation_date)
  puts "Creating patients for #{creation_date}"

  10.times do
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

  3.times do
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

  3.times do
    FactoryBot.create(:prescription_drug, patient: patient,
                      facility: patient.registration_facility,
                      created_at: creation_date,
                      updated_at: creation_date)
  end
end

def create_blood_pressures(patient, creation_date)
  puts "Creating blood pressures for #{creation_date}"

  3.times do
    FactoryBot.create(:blood_pressure, :under_control,
                      patient: patient,
                      facility: patient.registration_facility,
                      user: patient.registration_user,
                      created_at: creation_date,
                      updated_at: creation_date,
                      recorded_at: creation_date)

    FactoryBot.create(:blood_pressure, :high,
                      patient: patient,
                      facility: patient.registration_facility,
                      user: patient.registration_user,
                      created_at: creation_date,
                      updated_at: creation_date,
                      recorded_at: creation_date)

    FactoryBot.create(:blood_pressure, :very_high,
                      patient: patient,
                      facility: patient.registration_facility,
                      user: patient.registration_user,
                      created_at: creation_date,
                      updated_at: creation_date,
                      recorded_at: creation_date)

    FactoryBot.create(:blood_pressure, :critical,
                      patient: patient,
                      facility: patient.registration_facility,
                      user: patient.registration_user,
                      created_at: creation_date,
                      updated_at: creation_date,
                      recorded_at: creation_date)
  end
end

def create_appointments(patient, creation_date)
  puts "Creating appointments for #{creation_date}"

  3.times do
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

  number_of_months.times do |month_number|
    creation_date = month_number.months.ago

    organization = create_organization(creation_date)
    create_admins(organization)

    puts
  end
end

create_seed_data(number_of_months)

# TwilioSmsDeliveryDetail
#
# MasterUser
# PhoneNumberAuthentication
# UserAuthentication

