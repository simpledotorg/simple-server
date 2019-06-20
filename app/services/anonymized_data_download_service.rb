require 'csv'

class AnonymizedDataDownloadService
  def run_for_district(recipient_name, recipient_email, district_name, organization_id)
    begin
      organization_district = OrganizationDistrict.new(district_name, Organization.find(organization_id))
      organization_district_patients = organization_district.facilities.flat_map(&:patients)
      anonymized_data = anonymize(organization_district_patients)

      AnonymizedDataDownloadMailer
        .with(recipient_name: recipient_name,
              recipient_email: recipient_email,
              anonymized_data: anonymized_data)
        .mail_anonymized_data
        .deliver_later
    rescue StandardError => e
      puts "Caught error: #{e.inspect}"
    end
  end

  def run_for_facility(recipient_name, recipient_email, facility_id)
    begin
      facility = Facility.find(facility_id)
      facility_patients = facility.patients
      anonymized_data = anonymize(facility_patients)

      AnonymizedDataDownloadMailer
        .with(recipient_name: recipient_name,
              recipient_email: recipient_email,
              anonymized_data: anonymized_data)
    rescue StandardError => e
      puts "Caught error: #{e.inspect}"
    end
  end

  private

  def anonymize(patients)
    patient_ids = patients.map(&:id).to_set

    csv_data = Hash.new

    patients_csv_file = CSVGeneration::patients_csv(patients)
    csv_data[AnonymizedDataConstants::PATIENTS_FILE] = patients_csv_file

    blood_pressures = BloodPressure.all.select { |bp| patient_ids.include?(bp.patient_id) }
    bps_csv_file = CSVGeneration::bps_csv(blood_pressures)
    csv_data[AnonymizedDataConstants::BPS_FILE] = bps_csv_file

    prescriptions = PrescriptionDrug.all.select { |pd| patient_ids.include?(pd.patient_id) }
    meds_csv_file = CSVGeneration::medicines_csv(prescriptions)
    csv_data[AnonymizedDataConstants::MEDICINES_FILE] = meds_csv_file

    appointments = Appointment.all.select { |app| patient_ids.include?(app.patient_id) }
    appointments_csv_file = CSVGeneration::appointments_csv(appointments)
    csv_data[AnonymizedDataConstants::APPOINTMENTS_FILE] = appointments_csv_file

    communications = appointments.flat_map(&:communications)
    sms_reminders_file = CSVGeneration::sms_reminders(communications)
    csv_data[AnonymizedDataConstants::SMS_REMINDERS_FILE] = sms_reminders_file

    phone_calls = appointments.flat_map(&:communications)
    phone_calls_file = CSVGeneration::phone_calls(phone_calls)
    csv_data[AnonymizedDataConstants::PHONE_CALLS_FILE] = phone_calls_file

    csv_data
  end

  module CSVGeneration
    UNAVAILABLE = 'Unavailable'

    def self.hash_uuid(original_uuid)
      UUIDTools::UUID.md5_create(UUIDTools::UUID_DNS_NAMESPACE, { uuid: original_uuid }.to_s).to_s
    end

    def self.patients_csv(patients)
      CSV.generate(headers: true) do |csv|
        csv << AnonymizedDataConstants.patient_headers.map(&:titleize)

        patients.each do |patient|
          user_id = User.where(id: patient.registration_user_id).first
          facility_name = Facility.where(id: patient.registration_facility_id).first&.name

          csv << [
            hash_uuid(patient.id),
            patient.created_at,
            patient.recorded_at,
            original_else_blank_value(facility_name),
            hashed_else_blank_value(user_id),
            patient.age,
            patient.gender
          ]
        end
      end
    end

    def self.bps_csv(blood_pressures)
      CSV.generate(headers: true) do |csv|
        csv << AnonymizedDataConstants.bp_headers.map(&:titleize)

        blood_pressures.each do |bp|
          facility_name = Facility.where(id: bp.facility_id).first&.name

          csv << [
            hash_uuid(bp.id),
            hash_uuid(bp.patient_id),
            bp.created_at,
            bp.recorded_at,
            original_else_blank_value(facility_name),
            hashed_else_blank_value(bp.user_id),
            bp.systolic,
            bp.diastolic
          ]
        end
      end
    end

    def self.medicines_csv(medicines)
      CSV.generate(headers: true) do |csv|
        csv << AnonymizedDataConstants.medicines_headers.map(&:titleize)

        medicines.each do |med|
          user_id = med.patient.registration_user_id
          facility_name = Facility.where(id: med.facility_id).first&.name

          csv << [
            hash_uuid(med.id),
            hash_uuid(med.patient_id),
            med.created_at,
            original_else_blank_value(facility_name),
            hashed_else_blank_value(user_id),
            med.name,
            med.dosage
          ]
        end
      end
    end

    def self.appointments_csv(appointments)
      CSV.generate(headers: true) do |csv|
        csv << AnonymizedDataConstants.appointment_headers.map(&:titleize)

        appointments.each do |app|
          user_id = app.patient.registration_user_id
          facility_name = Facility.where(id: app.facility_id).first&.name

          csv << [
            hash_uuid(app.id),
            hash_uuid(app.patient_id),
            app.created_at,
            original_else_blank_value(facility_name),
            hashed_else_blank_value(user_id),
            app.scheduled_date,
            app.status,
            original_else_blank_value(app.agreed_to_visit),
            original_else_blank_value(app.remind_on),
          ]
        end
      end
    end

    def self.sms_reminders(communications)
      CSV.generate(headers: true) do |csv|
        csv << AnonymizedDataConstants::sms_reminders_headers.map(&:titleize)

        communications.each do |comm|
          patient_id = comm.appointment.patient.id

          csv << [
            hash_uuid(comm.id),
            hash_uuid(comm.appointment_id),
            hashed_else_blank_value(patient_id),
            hashed_else_blank_value(comm.user_id),
            comm.created_at,
            comm.communication_type,
            comm.communication_result,
          ]
        end
      end
    end

    def self.phone_calls(phone_calls)
      CSV.generate(headers: true) do |csv|
        csv << AnonymizedDataConstants::phone_calls_headers.map(&:titleize)

        phone_calls.each do |call|
          csv << [
            hash_uuid(call.id),
            call.created_at,
            call.result,
            call.duration,
            call.start_time,
            call.end_time
          ]
        end
      end
    end

    private

    def self.original_else_blank_value(value)
      if value.blank?
        UNAVAILABLE
      else
        value
      end
    end

    def self.hashed_else_blank_value(value)
      if value.blank?
        UNAVAILABLE
      else
        hash_uuid(value)
      end
    end
  end

  module AnonymizedDataConstants
    PATIENTS_FILE = 'patients.csv'
    BPS_FILE = 'blood_pressures.csv'
    MEDICINES_FILE = 'medicines.csv'
    APPOINTMENTS_FILE = 'appointments.csv'
    SMS_REMINDERS_FILE = 'sms_reminders.csv'
    PHONE_CALLS_FILE = 'phone_calls.csv'

    def self.patient_headers
      %w[id created_at registration_date facility_name user_id age gender]
    end

    def self.bp_headers
      %w[id patient_id created_at bp_date facility_name user_id bp_systolic bp_diastolic]
    end

    def self.medicines_headers
      %w[id patient_id created_at facility_name user_id medicine_name dosage]
    end

    def self.appointment_headers
      %w[id patient_id created_at facility_name user_id scheduled_date status agreed_to_visit remind_on]
    end

    def self.sms_reminders_headers
      %w[id appointment_id patient_id user_id created_at communication_type communication_result]
    end

    def self.phone_calls_headers
      %w[id created_at result duration start_time end_time]
    end
  end
end
