class Api::V4::Models
  class << self
    def timestamp
      {type: :string,
       format: "date-time",
       description: "Timestamp with millisecond precision."}
    end

    def month
      {type: :string,
       pattern: '[1-9]{4}\-[0-9]{2}'}
    end

    def uuid
      {type: :string,
       format: :uuid,
       pattern: '[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}'}
    end

    def non_empty_string
      {type: :string,
       minLength: 1,
       description: "This string should not be empty."}
    end

    def nullable_timestamp
      timestamp.merge(type: [:string, "null"])
    end

    def bcrypt_password
      {type: :string,
       pattern: '^\$[0-9a-z]{2}\$[0-9]{2}\$[A-Za-z0-9\.\/]{53}$',
       description: "Bcrypt password digest"}
    end

    def array_of(type)
      {type: ["null", :array],
       items: {"$ref" => "#/definitions/#{type}"}}
    end

    def nullable_enum(enum_values)
      {type: [:string, "null"], enum: enum_values << nil}
    end

    def blood_sugar
      {type: :object,
       properties: {
         id: {"$ref" => "#/definitions/uuid"},
         blood_sugar_type: {type: :string, enum: BloodSugar.blood_sugar_types.keys},
         blood_sugar_value: {type: :number},
         deleted_at: {"$ref" => "#/definitions/nullable_timestamp"},
         created_at: {"$ref" => "#/definitions/timestamp"},
         updated_at: {"$ref" => "#/definitions/timestamp"},
         recorded_at: {"$ref" => "#/definitions/timestamp"},
         patient_id: {"$ref" => "#/definitions/uuid"},
         facility_id: {"$ref" => "#/definitions/uuid"},
         user_id: {"$ref" => "#/definitions/uuid"}
       },
       required: %w[id blood_sugar_type blood_sugar_value created_at updated_at patient_id facility_id user_id]}
    end

    def login_patient
      {
        type: :object,
        properties: {
          id: {"$ref" => "#/definitions/uuid"},
          access_token: {"$ref" => "#/definitions/non_empty_string"},
          passport: {
            type: :object,
            properties: {
              id: {"$ref" => "#/definitions/uuid"},
              shortcode: {"$ref" => "#/definitions/non_empty_string"}
            }
          }
        }
      }
    end

    def patient
      {
        type: :object,
        properties: {
          id: {"$ref" => "#/definitions/uuid"},
          full_name: {"$ref" => "#/definitions/non_empty_string"},
          age: {type: [:integer, "null"]},
          gender: {type: :string, enum: Patient::GENDERS},
          status: {type: :string, enum: Patient::STATUSES},
          recorded_at: {"$ref" => "#/definitions/timestamp"},
          reminder_consent: {type: :string, enum: Patient.reminder_consents.keys},
          phone_numbers: {type: ["null", :array], items: patient_phone_number},
          address: patient_address,
          registration_facility: patient_facility,
          medical_history: patient_medical_history,
          blood_pressures: {type: ["null", :array], items: patient_blood_pressure},
          blood_sugars: {type: ["null", :array], items: patient_blood_sugar},
          appointments: {type: ["null", :array], items: patient_appointment},
          medications: {type: ["null", :array], items: patient_medication}
        }
      }
    end

    def retention
      {
        type: :object,
        properties: {
          type: {
            type: :string,
            enum: Api::V4::PatientsController::RETENTION_TYPES.values,
            description: "This enum might have more values in the future."
          },
          duration_seconds: {
            type: :integer,
            description: "This key is only present in the response when the retention type is temporary."
          }
        }
      }
    end

    def lookup_patient
      Api::V3::Models.nested_patient.deep_merge(
        properties: {
          appointments: {"$ref" => "#/definitions/appointments"},
          blood_pressures: {"$ref" => "#/definitions/blood_pressures"},
          blood_sugars: {"$ref" => "#/definitions/blood_sugars"},
          medical_history: {"$ref" => "#/definitions/nullable_medical_history"},
          prescription_drugs: {"$ref" => "#/definitions/prescription_drugs"},
          retention: retention
        },
        description: "Sync a single patient to a device",
        required: %w[appointments blood_pressures blood_sugars medical_history prescription_drugs retention]
      )
    end

    def patient_phone_number
      {
        type: :object,
        properties: {
          id: {"$ref" => "#/definitions/uuid"},
          number: {"$ref" => "#/definitions/non_empty_string"}
        }
      }
    end

    def patient_address
      {
        type: :object,
        properties: {
          id: {"$ref" => "#/definitions/uuid"},
          street_address: {type: [:string, "null"]},
          village_or_colony: {type: [:string, "null"]},
          district: {type: [:string, "null"]},
          zone: {type: [:string, "null"]},
          state: {type: [:string, "null"]},
          country: {type: [:string, "null"]},
          pin: {type: [:string, "null"]}
        }
      }
    end

    def patient_facility
      {
        type: :object,
        properties: {
          id: {"$ref" => "#/definitions/uuid"},
          name: {"$ref" => "#/definitions/non_empty_string"},
          street_address: {type: [:string, "null"]},
          village_or_colony: {type: [:string, "null"]},
          district: {type: [:string, "null"]},
          state: {type: [:string, "null"]},
          country: {type: [:string, "null"]},
          pin: {type: [:string, "null"]}
        }
      }
    end

    def patient_medical_history
      {
        type: :object,
        properties: {
          chronic_kidney_disease: {type: :string, enum: MedicalHistory::MEDICAL_HISTORY_ANSWERS.keys},
          diabetes: {type: :string, enum: MedicalHistory::MEDICAL_HISTORY_ANSWERS.keys},
          hypertension: {type: :string, enum: MedicalHistory::MEDICAL_HISTORY_ANSWERS.keys},
          prior_heart_attack: {type: :string, enum: MedicalHistory::MEDICAL_HISTORY_ANSWERS.keys},
          prior_stroke: {type: :string, enum: MedicalHistory::MEDICAL_HISTORY_ANSWERS.keys}
        }
      }
    end

    def patient_blood_pressure
      {
        type: :object,
        properties: {
          systolic: {type: :integer},
          diastolic: {type: :integer},
          recorded_at: {"$ref" => "#/definitions/timestamp"},
          facility: patient_facility
        }
      }
    end

    def patient_blood_sugar
      {
        type: :object,
        properties: {
          blood_sugar_value: {type: :number},
          blood_sugar_type: {type: :string, enum: BloodSugar.blood_sugar_types.keys},
          recorded_at: {"$ref" => "#/definitions/timestamp"},
          facility: patient_facility
        }
      }
    end

    def patient_appointment
      {
        type: :object,
        properties: {
          scheduled_date: {type: :string, format: :date},
          status: {type: :string, enum: Appointment.statuses.keys},
          facility: patient_facility
        }
      }
    end

    def patient_medication
      {
        type: :object,
        properties: {
          name: {"$ref" => "#/definitions/non_empty_string"},
          dosage: {type: :string},
          rxnorm_code: {type: :string},
          is_protocol_drug: {type: :boolean}
        }
      }
    end

    def user
      {type: :object,
       properties: {
         id: {"$ref" => "#/definitions/uuid"},
         deleted_at: {"$ref" => "#/definitions/nullable_timestamp"},
         created_at: {"$ref" => "#/definitions/timestamp"},
         updated_at: {"$ref" => "#/definitions/timestamp"},
         full_name: {"$ref" => "#/definitions/non_empty_string"},
         phone_number: {"$ref" => "#/definitions/non_empty_string"},
         password_digest: {"$ref" => "#/definitions/bcrypt_password"},
         registration_facility_id: {"$ref" => "#/definitions/uuid"},
         sync_approval_status: {type: [:string, "null"]},
         sync_approval_status_reason: {type: [:string, "null"]},
         capabilities: app_user_capabilities,
         teleconsultation_phone_number: {"$ref" => "#/definitions/non_empty_string"}
       },
       required: %w[id
         created_at
         updated_at
         full_name
         phone_number
         password_digest
         registration_facility_id]}
    end

    def medical_officer
      {
        type: :object,
        properties: {
          id: {"$ref" => "#/definitions/uuid"},
          full_name: {"$ref" => "#/definitions/non_empty_string"},
          teleconsultation_phone_number: {"$ref" => "#/definitions/non_empty_string"}
        }
      }
    end

    def facility_medical_officer
      {
        type: :object,
        properties: {
          id: {"$ref" => "#/definitions/uuid"},
          facility_id: {"$ref" => "#/definitions/uuid"},
          medical_officers: {type: ["null", :array], items: medical_officer},
          created_at: {"$ref" => "#/definitions/timestamp"},
          updated_at: {"$ref" => "#/definitions/timestamp"},
          deleted_at: {"$ref" => "#/definitions/nullable_timestamp"}
        }
      }
    end

    def teleconsultation
      {
        type: :object,
        properties: {
          id: {"$ref" => "#/definitions/uuid"},
          patient_id: {"$ref" => "#/definitions/uuid"},
          medical_officer_id: {"$ref" => "#/definitions/uuid"},
          request: {
            type: [:object, "null"],
            properties: {
              requester_id: {"$ref" => "#/definitions/uuid"},
              facility_id: {"$ref" => "#/definitions/uuid"},
              requested_at: {"$ref" => "#/definitions/timestamp"},
              requester_completion_status: nullable_enum(Teleconsultation.requester_completion_statuses.keys)
            }
          },
          record: {
            type: [:object, "null"],
            properties: {
              recorded_at: {"$ref" => "#/definitions/timestamp"},
              teleconsultation_type: {type: :string, enum: Teleconsultation::TELECONSULTATION_TYPES.keys},
              patient_took_medicines: {type: :string, enum: Teleconsultation.patient_took_medicines.keys},
              patient_consented: {type: :string, enum: Teleconsultation.patient_consenteds.keys},
              medical_officer_number: {type: [:string, "null"]}
            }
          },
          created_at: {"$ref" => "#/definitions/timestamp"},
          updated_at: {"$ref" => "#/definitions/timestamp"},
          deleted_at: {"$ref" => "#/definitions/nullable_timestamp"}
        }
      }
    end

    def find_user
      {type: :object,
       properties: {
         id: {"$ref" => "#/definitions/uuid"},
         sync_approval_status: {type: [:string, "null"]}
       },
       required: %w[id]}
    end

    def app_user_capability_values
      {type: :string, enum: User::CAPABILITY_VALUES.values}
    end

    def app_user_capabilities
      {type: :object,
       properties: User::APP_USER_CAPABILITIES.product([app_user_capability_values]).to_h}
    end

    def activate_user
      {type: :object,
       properties: {
         id: {"$ref" => "#/definitions/uuid"},
         password: {"$ref" => "#/definitions/non_empty_string"}
       },
       required: %w[id password]}
    end

    def medication
      {type: :object,
       properties: {
         id: {"$ref" => "#/definitions/uuid"},
         name: {"$ref" => "#/definitions/non_empty_string"},
         category: nullable_enum(Medication::CATEGORIES.keys),
         frequency: nullable_enum(Medication::FREQUENCIES.keys),
         composition: {type: [:string, "null"]},
         dosage: {type: [:string, "null"]},
         rxnorm_code: {type: [:string, "null"]},
         protocol: {type: [:string, "null"], enum: [:yes, :no]},
         common: {type: [:string, "null"], enum: [:yes, :no]},
         created_at: {"$ref" => "#/definitions/timestamp"},
         updated_at: {"$ref" => "#/definitions/timestamp"},
         deleted_at: {"$ref" => "#/definitions/nullable_timestamp"}
       },
       required: %w[id name created_at updated_at]}
    end

    def call_result
      {type: :object,
       properties: {
         id: {"$ref" => "#/definitions/uuid"},
         user_id: {"$ref" => "#/definitions/uuid"},
         appointment_id: {"$ref" => "#/definitions/uuid"},
         remove_reason: nullable_enum(CallResult.remove_reasons.keys),
         result_type: {type: :string, enum: CallResult.result_types.keys},
         deleted_at: {"$ref" => "#/definitions/nullable_timestamp"},
         created_at: {"$ref" => "#/definitions/timestamp"},
         updated_at: {"$ref" => "#/definitions/timestamp"}
       },
       required: %w[id user_id appointment_id result_type created_at updated_at]}
    end

    def drug_stock
      {type: :object,
       properties: {
         protocol_drug_id: {"$ref" => "#/definitions/uuid"},
         in_stock: {type: :integer},
         received: {type: :integer}
       },
       required: %w[protocol_drug_id in_stock received]}
    end

    def definitions
      {
        activate_user: activate_user,
        address: Api::V3::Models.address,
        app_user_capabilities: app_user_capabilities,
        appointment: Api::V3::Models.appointment,
        appointments: array_of("appointment"),
        bcrypt_password: bcrypt_password,
        blood_pressure: Api::V3::Models.blood_pressure,
        blood_pressures: array_of("blood_pressure"),
        blood_sugar: blood_sugar,
        blood_sugars: array_of("blood_sugar"),
        call_result: call_result,
        call_results: array_of("call_result"),
        drug_stock: drug_stock,
        facility_medical_officer: facility_medical_officer,
        facility_medical_officers: array_of("facility_medical_officer"),
        find_user: find_user,
        login_patient: login_patient,
        lookup_patient: lookup_patient,
        lookup_patients: array_of("lookup_patient"),
        nullable_medical_history: Api::V3::Models.medical_history.merge(type: [:object, "null"]),
        medical_officer: medical_officer,
        medication: medication,
        medications: array_of("medication"),
        month: month,
        non_empty_string: non_empty_string,
        nullable_timestamp: nullable_timestamp,
        nullable_uuid: Api::V3::Models.nullable_uuid,
        patient: patient,
        patient_business_identifier: Api::V3::Models.patient_business_identifier,
        patient_business_identifiers: array_of("patient_business_identifier"),
        phone_number: Api::V3::Models.phone_number,
        phone_numbers: array_of("phone_number"),
        prescription_drug: Api::V3::Models.prescription_drug,
        prescription_drugs: array_of("prescription_drug"),
        teleconsultation: teleconsultation,
        teleconsultations: array_of("teleconsultation"),
        timestamp: timestamp,
        user: user,
        uuid: uuid
      }
    end
  end
end
