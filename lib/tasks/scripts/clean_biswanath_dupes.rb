class CleanBiswanathDupes
  # * Import BD data locally
  # * Identify the dupe patients (code)
  # * For the dupe patients, identify the measurements - Appointments, BPs, MHs, Medications, Passports, NIDs, phone_numbers, addresses, patient, Observations, encounters, blood_sugars (code)
  # * Look up the real patients for the dupes
  # * Look up the real patients separately in this order of matchability
  #   * matcher => name, age, address, phone_numbers
  #   * matcher => name, age, address
  #   * matcher => name, age
  # * Port the measurements from dupe patient data to real patient data
  #
  # Syncs with user
  #   * BloodPressure
  #   * BloodSugar
  #   * Encounters
  #   * Observations
  #   * Appointments
  #   * Prescription Drug
  #   * MedicalHistory
  #
  # Syncs w/o user
  #   * Patient
  #   * Address (patient)  (confirm with mobile team if phone number edit is in place)
  #   * BusinessIdentifier (confirm with mobile team if phone number edit is in place)
  #   * PatientPhoneNumber (confirm with mobile team if phone number edit is in place)

  def self.call(*args)
    new(*args).call
  end

  attr_accessor :dryrun, :exact_matches, :ambiguous_matches, :no_matches

  def initialize(dryrun: false)
    @dryrun = dryrun
    @exact_matches = {}
    @ambiguous_matches = []
    @no_matches = []
  end

  def call
    puts 'Identifying patient matches...'
    identify_patient_matches

    return if dryrun

    puts 'Porting activity of patients with exact matches...'
    port_exact_match_activity

    puts 'Porting unmatched patients to the import user...'
    port_unmatched_patients

    puts 'Deactiviting ambiguous patients...'
    deactivate_ambiguous_patients

    puts 'Complete. Goodbye.'
  end

  def identify_patient_matches
    duplicate_patients.each do |patient|
      matches = match_by_name_age(patient)
      if matches.count == 0
        (no_matches << patient) && next
      end

      if matches.count == 1
        (exact_matches[patient.id] = matches.first.id) && next
      end

      matches = match_by_name_age_address(patient)
      if matches.count == 1
        (exact_matches[patient.id] = matches.first.id) && next
      end

      matches = match_by_name_age_address_phone(patient)
      if matches.count == 1
        (exact_matches[patient.id] = matches.first.id) && next
      end

      ambiguous_matches << patient
    end

    print_summary
  end

  def port_exact_match_activity
    "Pretending to port exact-match activity..."
  end

  def port_unmatched_patients
    no_matches.each do |patient|
      patient.update!(registration_user: import_user)
    end
  end

  def deactivate_ambiguous_patients
    ambiguous_matches.each(&:discard_data)
  end

  def print_summary
    puts "Matched patients: #{exact_matches.count}"
    puts "Unmatched patients: #{ambiguous_matches.count}"
    puts "No matches patients: #{no_matches.count}"
  end

  def duplicate_patients
    @duplicate_patients ||= duplicate_user.registered_patients
  end

  def duplicate_user
    @duplicate_user ||= User.find('2b469d02-f746-4550-bb91-6651143ca8cc')
  end

  def import_user
    @import_user ||= User.find_by!(full_name: 'biswanath-import-user')
  end

  def match_by_name_age(patient)
    Patient.where(age: patient.age, full_name: patient.full_name).where.not(id: patient.id)
  end

  def match_by_name_age_address(patient)
    address_attrs = patient.address.slice(:street_address, :village_or_colony, :district, :state, :country, :pin)

    match_by_name_age(patient).joins(:address).where(addresses: address_attrs)
  end

  def match_by_name_age_address_phone(patient)
    match_by_name_age_address(patient).select do |match|
      patient.latest_phone_number && (patient.latest_phone_number == match.latest_phone_number)
    end
  end
end
