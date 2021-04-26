module PatientImport
  class SpreadsheetTransformer
    attr_reader :data, :facility

    def self.transform(*args)
      new(*args).transform
    end

    def initialize(data, facility:)
      @data = data
      @facility = facility
    end

    def transform
      rows.map do |row|
        params_for(row)
      end
    end

    def rows
      # Skip first row, it is also headers
      @rows ||= CSV.parse(data, headers: true)[1..-1].map do |row|
        row.to_h.with_indifferent_access
      end
    end

    def params_for(row)
      patient_id = SecureRandom.uuid
      business_identifier_id = SecureRandom.uuid
      phone_number_id = SecureRandom.uuid
      address_id = SecureRandom.uuid
      medical_history_id = SecureRandom.uuid

      {
        patient: {
          id: patient_id,
          registration_facility_id: registration_facility_id,
          recorded_at: timestamp(row[:registration_date]),
          full_name: row[:full_name],
          age: row[:age].to_i,
          age_updated_at: timestamp(row[:registration_date]),
          gender: row[:gender].downcase,
          status: patient_status(row),
          created_at: timestamp(row[:registration_date]),
          updated_at: timestamp(row[:registration_date]),

          business_identifiers: [{
            id: business_identifier_id,
            identifier_type: row[:identifier_type],
            identifier: row[:identifier],
            created_at: timestamp(row[:registration_date]),
            updated_at: timestamp(row[:registration_date]),
          }],

          phone_numbers: [{
            id: phone_number_id,
            number: row[:phone],
            phone_type: :mobile,
            active: true,
            created_at: timestamp(row[:registration_date]),
            updated_at: timestamp(row[:registration_date])
          }],

          address: {
            id: address_id,
            street_address: row[:address],
            village_or_colony: row[:village],
            zone: row[:zone],
            state: row[:state],
            country: CountryConfig.current[:name],
            created_at: timestamp(row[:registration_date]),
            updated_at: timestamp(row[:registration_date])
          }
        },
        medical_history: {
          id: medical_history_id,
          patient_id: patient_id,
          hypertension: row[:medical_history_hypertension],
          diabetes: row[:medical_history_diabetes],
          prior_heart_attack: row[:medical_history_heart_attack],
          prior_stroke: row[:medical_history_stroke],
          chronic_kidney_disease: row[:medical_history_kidney_disease],
          diagnosed_with_hypertension: row[:medical_history_hypertension],
          receiving_treatment_for_hypertension: "yes",
          created_at: timestamp(row[:registration_date]),
          updated_at: timestamp(row[:registration_date])
        },
        blood_pressures: [
          first_blood_pressure(row, patient_id: patient_id),
          last_blood_pressure(row, patient_id: patient_id)
        ].compact,
        prescription_drugs: [
          *first_prescription_drugs(row, patient_id: patient_id),
          *last_prescription_drugs(row, patient_id: patient_id)
        ]
      }.with_indifferent_access
    end

    def registration_facility_id
      facility.id
    end

    def import_user
      @import_user = PatientImport::ImportUser.find_or_create
    end

    def create_import_user
      user = User.new(
        full_name: "import-user",
        organization_id: Organization.take,
        device_created_at: Time.current,
        device_updated_at: Time.current
      )
      phone_number_authentication = PhoneNumberAuthentication.new(
        phone_number: IMPORT_USER_PHONE_NUMBER,
        password: "#{rand(10)}#{rand(10)}#{rand(10)}#{rand(10)}",
        registration_facility_id: facility.id
      ).tap do |pna|
        pna.set_otp
        pna.invalidate_otp
        pna.set_access_token
      end

      user.phone_number_authentications = [phone_number_authentication]
      user.sync_approval_denied("bot user for import")
      user.save!

      user
    end

    def patient_status(row)
      row[:died] == "yes" ? :dead : :active
    end

    def first_blood_pressure(row, patient_id:)
      return nil unless row[:first_visit_date].present?

      {
        id: SecureRandom.uuid,
        patient_id: patient_id,
        facility_id: registration_facility_id,
        user_id: import_user.id,
        systolic: row[:first_visit_bp_systolic].to_i,
        diastolic: row[:first_visit_bp_diastolic].to_i,
        recorded_at: timestamp(row[:first_visit_date]),
        created_at: timestamp(row[:first_visit_date]),
        updated_at: timestamp(row[:first_visit_date])
      }
    end

    def last_blood_pressure(row, patient_id:)
      return nil unless row[:last_visit_date].present?

      {
        id: SecureRandom.uuid,
        patient_id: patient_id,
        facility_id: registration_facility_id,
        user_id: import_user.id,
        systolic: row[:last_visit_bp_systolic].to_i,
        diastolic: row[:last_visit_bp_diastolic].to_i,
        recorded_at: timestamp(row[:last_visit_date]),
        created_at: timestamp(row[:last_visit_date]),
        updated_at: timestamp(row[:last_visit_date])
      }
    end

    def first_prescription_drugs(row, patient_id:)
      drug_names = [
        row[:first_visit_medication_1],
        row[:first_visit_medication_2],
        row[:first_visit_medication_3],
        row[:first_visit_medication_4],
        row[:first_visit_medication_5]
      ]

      drugs = drug_names.map do |name|
        medication(
          name: name,
          patient_id: patient_id,
          created_at: row[:first_visit_date]
        )
      end.compact

      # Delete the first drugs if last drugs are available
      if last_prescription_drugs(row, patient_id: patient_id).any?
        drugs.each do |drug|
          drug.merge!(
            is_deleted: true,
            updated_at: timestamp(row[:last_visit_date]),
            deleted_at: timestamp(row[:last_visit_date])
          )
        end
      end

      drugs
    end

    def last_prescription_drugs(row, patient_id:)
      drug_names = [
        row[:last_visit_medication_1],
        row[:last_visit_medication_2],
        row[:last_visit_medication_3],
        row[:last_visit_medication_4],
        row[:last_visit_medication_5]
      ]

      drug_names.map do |name|
        medication(
          name: name,
          patient_id: patient_id,
          created_at: row[:last_visit_date]
        )
      end.compact
    end

    def medication(name:, patient_id:, created_at:)
      medication_record = medication_by_name_dosage_and_frequency(name) || medication_by_name_and_dosage(name)

      return nil unless medication_record.present?

      {
        id: SecureRandom.uuid,
        patient_id: patient_id,
        facility_id: registration_facility_id,
        name: medication_record.name,
        rxnorm_code: medication_record.rxnorm_code,
        dosage: medication_record.dosage,
        is_protocol_drug: protocol_drug?(medication_record),
        created_at: timestamp(created_at),
        updated_at: timestamp(created_at),
        is_deleted: false
      }
    end

    def protocol_drug?(medication)
      facility.protocol.protocol_drugs.exists?(name: medication.name, dosage: medication.dosage)
    end

    def localized_frequency(medication)
      return nil unless medication.frequency.present?
      I18n.translate("helpers.label.drug.frequency.#{medication.frequency}", locale: CountryConfig.current[:dashboard_locale])
    end

    def medication_by_name_and_dosage(name)
      Medication.all.to_a.find do |medication|
        name.gsub(/\s+/, "") == "#{medication.name}#{medication.dosage}".gsub(/\s+/, "")
      end
    end

    def medication_by_name_dosage_and_frequency(name)
      Medication.all.to_a.find do |medication|
        name.gsub(/\s+/, "") == "#{medication.name}#{medication.dosage}#{localized_frequency(medication)}".gsub(/\s+/, "")
      end
    end

    def timestamp(time)
      Time.parse(time)
    rescue ArgumentError
      nil
    end
  end
end
