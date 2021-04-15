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
      {
        patient: {
          registration_facility_id: registration_facility_id(row),
          recorded_at: row[:registration_date],
          full_name: row[:full_name],
          age: row[:age],
          gender: row[:gender],
          status: patient_status(row)
        },
        business_identifier: {
          identifier_type: row[:identifier_type],
          identifier: row[:identifier]
        },
        phone_number: {
          number: row[:phone],
          phone_type: :mobile,
          active: true
        },
        address: {
          street_address: row[:address],
          village_or_colony: row[:village],
          zone: row[:zone],
          state: row[:state],
          country: CountryConfig.current[:name]
        },
        medical_history: {
          hypertension: row[:medical_history_hypertension],
          diabetes: row[:medical_history_diabetes],
          prior_heart_attack: row[:medical_history_heart_attack],
          prior_stroke: row[:medical_history_stroke],
          chronic_kidney_disease: row[:medical_history_kidney_disease]
        },
        blood_pressures: [
          first_blood_pressure(row),
          last_blood_pressure(row)
        ].compact,
        prescription_drugs: [
          *first_prescription_drugs(row),
          *last_prescription_drugs(row)
        ]
      }
    end

    def registration_facility_id(row)
      Facility.find_by(name: row[:registration_facility])&.id
    end

    def patient_status(row)
      row[:died] == "yes" ? :dead : :active
    end

    def first_blood_pressure(row)
      return nil unless row[:first_visit_date].present?

      {
        systolic: row[:first_visit_bp_systolic],
        diastolic: row[:first_visit_bp_diastolic],
        recorded_at: row[:first_visit_date]
      }
    end

    def last_blood_pressure(row)
      return nil unless row[:last_visit_date].present?

      {
        systolic: row[:last_visit_bp_systolic],
        diastolic: row[:last_visit_bp_diastolic],
        recorded_at: row[:last_visit_date]
      }
    end

    def first_prescription_drugs(row)
      drug_names = [
        row[:first_visit_medication_1],
        row[:first_visit_medication_2],
        row[:first_visit_medication_3],
        row[:first_visit_medication_4],
        row[:first_visit_medication_5]
      ]

      drugs = drug_names.map do |name|
        medication(name: name, created_at: row[:first_visit_date])
      end.compact

      # Delete the first drugs if last drugs are available
      if last_prescription_drugs(row).any?
        drugs.each do |drug|
          drug.merge!(
            is_deleted: true,
            deleted_at: row[:last_visit_date]
          )
        end
      end

      drugs
    end

    def last_prescription_drugs(row)
      drug_names = [
        row[:last_visit_medication_1],
        row[:last_visit_medication_2],
        row[:last_visit_medication_3],
        row[:last_visit_medication_4],
        row[:last_visit_medication_5]
      ]

      drug_names.map do |name|
        medication(name: name, created_at: row[:last_visit_date])
      end.compact
    end

    def medication(name:, created_at:)
      medication_record = medication_by_name_dosage_and_frequency(name) || medication_by_name_and_dosage(name)

      return nil unless medication_record.present?

      {
        name: medication_record.name,
        rxnorm_code: medication_record.rxnorm_code,
        dosage: medication_record.dosage,
        is_protocol_drug: protocol_drug?(medication_record),
        created_at: created_at
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
  end
end
