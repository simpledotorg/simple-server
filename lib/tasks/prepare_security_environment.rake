desc "Prepare security environment with necesssary data setup, and print audit prerequisites"
task prepare_security_environment: :environment do
  abort "This task can only be run in development or security environments!" unless Rails.env.development? || ENV.fetch("SIMPLE_SERVER_ENV") == "security"

  # Feature flags
  Flipper.disable(:auto_approve_users)
  Flipper.enable(:fixed_otp)

  # Mobile users
  user_pin = "1234"
  user_otp = "000000"
  users = User.sync_approval_status_allowed.joins(:phone_number_authentications).sample(5)

  users.each { |user| user.phone_number_authentication.update!(password: user_pin) }

  user_credentials = users.map do |user|
    {
      user_id: user.id,
      facility_id: user.registration_facility.id,
      access_token: user.access_token,
      phone_number: user.phone_number,
      password: user_pin,
      otp: user_otp
    }
  end

  facilities_with_users = Facility.where(id: PhoneNumberAuthentication.pluck(:registration_facility_id))
  teleconsultation_facility = facilities_with_users.sample
  medical_officer = teleconsultation_facility.users.first
  abort "Could not find user at teleconsultation facility. Please reseed and try again" unless medical_officer
  teleconsultation_facility.teleconsultation_medical_officers << medical_officer
  teleconsultation_facility.enable_teleconsultation = true
  teleconsultation_facility.save!

  medical_officer.phone_number_authentication.update!(password: user_pin)

  teleconsultation = {
    facility_name: teleconsultation_facility.name,
    phone_number: medical_officer.phone_number,
    password: user_pin
  }

  bp_passports = PatientBusinessIdentifier.simple_bp_passport.sample(5).map(&:identifier)

  dashboard_users = %(
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
    PassportAuthentication.create!(patient_business_identifier: bp_passport)

    {
      identifier: bp_passport.identifier,
      otp: user_otp
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
