desc "Get user credentials to attach to request headers"
task prepare_security_environment: :environment do
  abort "This task can only be run in development or security environments!" unless (Rails.env.development? || Rails.env.security?)

  # Feature flags
  Flipper.disable(:auto_approve_users)
  Flipper.enable(:fixed_otp)

  # Mobile users
  USER_PIN = "1234"
  USER_OTP = "000000"
  users = User.sync_approval_status_allowed.joins(:phone_number_authentications).sample(5)

  users.each { |user| user.phone_number_authentication.update!(password: USER_PIN) }

  user_credentials = users.map do |user|
    {
      user_id: user.id,
      facility_id: user.registration_facility.id,
      access_token: user.access_token,
      phone_number: user.phone_number,
      password: USER_PIN,
      otp: USER_OTP
    }
  end

  facilities_with_users = Facility.where(id: PhoneNumberAuthentication.pluck(:registration_facility_id))
  teleconsultation_facility = facilities_with_users.sample
  medical_officer = teleconsultation_facility.users.first
  abort "Could not find user at teleconsultation facility. Please reseed and try again" unless medical_officer
  teleconsultation_facility.teleconsultation_medical_officers << medical_officer
  teleconsultation_facility.enable_teleconsultation = true
  teleconsultation_facility.save!

  medical_officer.phone_number_authentication.update!(password: USER_PIN)

  teleconsultation = {
    facility_name: teleconsultation_facility.name,
    phone_number: medical_officer.phone_number,
    password: USER_PIN
  }

  bp_passports = PatientBusinessIdentifier.simple_bp_passport.sample(5).map(&:identifier)

  dashboard_users = %Q(
    Role: Admin User
    Authorization: Power User
    username: admin@simple.org
    password: Resolve2SaveLives


    Role: CVHO
    Authorization: Manager
    username: cvho@simple.org
    password: Resolve2SaveLives


    Role: District Official
    Authorization: View: Reports only
    username: district_official@simple.org
    password: Resolve2SaveLives


    Role: Medical Officer
    Authorization: View: Everything (reports plus patient-level information)
    username: medical_officer@simple.org
    password: Resolve2SaveLives


    Role: Power User
    Authorization: Power User
    username: power_user@simple.org
    password: Resolve2SaveLives


    Role: STS
    Authorization: View: Everything
    username: sts@simple.org
    password: Resolve2SaveLives
  )

  passport_authentications = PatientBusinessIdentifier.simple_bp_passport.sample(5).map do |bp_passport|
    auth = PassportAuthentication.create!(patient_business_identifier: bp_passport)

    {
      identifier: bp_passport.identifier,
      otp: USER_OTP
    }
  end

  puts "Mobile app user logins"
  puts "---------------"
  puts "Log into the Simple app using these user accounts"
  puts
  user_credentials.each_with_index do |cred, index|
    puts "User #{index + 1}"
    puts "  Phone number: #{cred[:phone_number]}"
    puts "  PIN code: #{cred[:password]}"
    puts "  OTP: #{cred[:otp]}"
    puts
  end

  puts "API Credentials"
  puts "---------------"
  puts "Attach the following request headers to your API requests"
  puts
  user_credentials.each_with_index do |cred, index|
    puts "User #{index + 1}"
    puts "  Authorization: Bearer #{cred[:access_token]}"
    puts "  X-User-ID: #{cred[:user_id]}"
    puts "  X-Facility-ID: #{cred[:facility_id]}"
    puts
  end

  puts "Teleconsultation"
  puts "---------------"
  puts "Teleconsultation is enabled at the facility: #{teleconsultation[:facility_name]}"
  puts "Use the following Simple app user to log in and perform teleconsultations"
  puts "  Phone number: #{teleconsultation[:phone_number]}"
  puts "  PIN code: #{teleconsultation[:password]}"
  puts

  puts "Dashboard user logins"
  puts "---------------"
  puts "Log into the Simple dashboard using these admin accounts"
  puts dashboard_users
  puts

  puts "BP Passports"
  puts "---------------"
  puts "Here are a few BP Passport IDs that can be used with the API"
  bp_passports.each { |id| puts "  #{id}" }
  puts

  puts "Patient API"
  puts "---------------"
  puts "Here are a few BP Passport IDs that can be used with the Patient API for individual patient login and lookup"
  passport_authentications.each do |auth|
    puts "  Identifier: #{auth[:identifier]}"
    puts "  OTP: #{auth[:otp]}"
    puts
  end
end
