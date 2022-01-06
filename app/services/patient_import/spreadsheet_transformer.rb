# frozen_string_literal: true

module PatientImport
  class SpreadsheetTransformer
    attr_reader :data, :facility

    def self.call(*args)
      new(*args).call
    end

    def initialize(data, facility:)
      @data = data
      @facility = facility
    end

    def call
      rows.map do |row|
        next if row[:registration_date].blank?

        params_for(row)
      end.compact
    end

    def rows
      # Skip first row, it is also headers
      @rows ||= CSV.parse(data, headers: true)[1..].map { |row|
        row.to_h.with_indifferent_access
      }
    end

    def params_for(row)
      patient_id = patient_id(row)
      address_id = SecureRandom.uuid
      medical_history_id = SecureRandom.uuid

      {
        patient: {
          id: patient_id,
          registration_facility_id: registration_facility_id,
          assigned_facility_id: registration_facility_id,
          recorded_at: timestamp(row[:registration_date]),
          full_name: row[:full_name],
          age: row[:age].to_i,
          age_updated_at: timestamp(row[:registration_date]),
          gender: gender(row[:gender]),
          status: patient_status(row),
          created_at: timestamp(row[:registration_date]),
          updated_at: timestamp(row[:registration_date]),

          business_identifiers: business_identifiers(row),

          phone_numbers: phone_numbers(row),

          address: {
            id: address_id,
            street_address: row[:address],
            village_or_colony: row[:village],
            zone: row[:zone] || facility.zone,
            district: row[:district] || facility.district,
            state: row[:state] || facility.state,
            country: CountryConfig.current[:name],
            created_at: timestamp(row[:registration_date]),
            updated_at: timestamp(row[:registration_date])
          }
        },
        medical_history: {
          id: medical_history_id,
          patient_id: patient_id,
          hypertension: history(row[:medical_history_hypertension]),
          diabetes: history(row[:medical_history_diabetes]),
          prior_heart_attack: history(row[:medical_history_heart_attack]),
          prior_stroke: history(row[:medical_history_stroke]),
          chronic_kidney_disease: history(row[:medical_history_kidney_disease]),
          diagnosed_with_hypertension: history(row[:medical_history_hypertension]),
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

    private

    def business_identifiers(row)
      return [] unless row[:identifier].present?

      [{
        id: SecureRandom.uuid,
        identifier_type: row[:identifier_type],
        identifier: row[:identifier],
        metadata: {
          assigning_user_id: import_user.id,
          assigning_facility_id: facility.id
        }.to_json,
        metadata_version: business_identifier_metadata_version(row),
        created_at: timestamp(row[:registration_date]),
        updated_at: timestamp(row[:registration_date])
      }]
    end

    def phone_numbers(row)
      return [] unless row[:phone].present?

      [{
        id: SecureRandom.uuid,
        number: row[:phone],
        phone_type: "mobile",
        active: true,
        created_at: timestamp(row[:registration_date]),
        updated_at: timestamp(row[:registration_date])
      }]
    end

    def first_blood_pressure(row, patient_id:)
      {
        id: SecureRandom.uuid,
        patient_id: patient_id,
        facility_id: registration_facility_id,
        user_id: import_user.id,
        systolic: row[:first_visit_bp_systolic].to_i,
        diastolic: row[:first_visit_bp_diastolic].to_i,
        recorded_at: timestamp(row[:registration_date]),
        created_at: timestamp(row[:registration_date]),
        updated_at: timestamp(row[:registration_date])
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

      drugs = drug_names.map { |name|
        medication(
          name: name,
          patient_id: patient_id,
          created_at: row[:registration_date]
        )
      }.compact

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

      drug_names.map { |name|
        medication(
          name: name,
          patient_id: patient_id,
          created_at: row[:last_visit_date]
        )
      }.compact
    end

    def patient_id(row)
      PatientBusinessIdentifier.find_by(
        identifier_type: row[:identifier_type],
        identifier: row[:identifier]
      )&.patient_id || SecureRandom.uuid
    end

    def business_identifier_metadata_version(row)
      case row[:identifier_type]
      when "simple_bp_passport"
        "org.simple.bppassport.meta.v1"
      else
        "org.simple.#{row[:identifier_type]}.meta.v1"
      end
    end

    def registration_facility_id
      facility.id
    end

    def import_user
      @import_user = PatientImport::ImportUser.find_or_create
    end

    def patient_status(row)
      row[:died]&.downcase&.in?(["yes", "y"]) ? Patient.statuses["dead"] : Patient.statuses["active"]
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
      }.compact
    end

    def protocol_drug?(medication)
      facility.protocol.protocol_drugs.exists?(name: medication.name, dosage: medication.dosage)
    end

    def localized_frequency(medication)
      return nil unless medication.frequency.present?
      I18n.translate("helpers.label.drug.frequency.#{medication.frequency}", locale: CountryConfig.current[:dashboard_locale])
    end

    def medication_by_name_and_dosage(name)
      return unless name.present?

      Medication.all.to_a.find do |medication|
        name.gsub(/\s+/, "") == "#{medication.name}#{medication.dosage}".gsub(/\s+/, "")
      end
    end

    def medication_by_name_dosage_and_frequency(name)
      return unless name.present?

      Medication.all.to_a.find do |medication|
        name.gsub(/\s+/, "") == "#{medication.name}#{medication.dosage}#{localized_frequency(medication)}".gsub(/\s+/, "")
      end
    end

    def gender(value)
      case value.presence&.downcase
      when "m", "male"
        "male"
      when "f", "female"
        "female"
      when "t", "transgender"
        "transgender"
      else
        value
      end
    end

    def history(value)
      value.presence&.downcase || "unknown"
    end

    def timestamp(time)
      Time.parse(time).rfc3339
    rescue ArgumentError, TypeError
      nil
    end
  end
end
