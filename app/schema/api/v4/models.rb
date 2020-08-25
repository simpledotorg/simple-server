class Api::V4::Models
  class << self
    def timestamp
      {type: :string,
       format: "date-time",
       description: "Timestamp with millisecond precision."}
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
         teleconsultation_phone_number: {"$ref" => "#/definitions/non_empty_string"},
         capabilities: app_user_capabilities
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
          full_name: {"$ref" =>  "#/definitions/non_empty_string" },
          teleconsultation_phone_number: {"$ref" =>  "#/definitions/non_empty_string" }
        }
      }
    end

    def teleconsultation_medical_officer
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
            type: :object,
            properties: {
              requester_id: {"$ref" => "#/definitions/uuid"},
              facility_id: {"$ref" => "#/definitions/uuid"},
              requested_at: {"$ref" => "#/definitions/timestamp"}
            }
          },
          record: {
            type: :object,
            properties: {
              recorded_at: {"$ref" => "#/definitions/timestamp"},
              teleconsultation_type: {type: :string, enum: Teleconsultation::TYPES.keys},
              patient_took_medicines: {type: :string, enum: Teleconsultation::TELECONSULTATION_ANSWERS.keys},
              patient_consented: {type: :string, enum: Teleconsultation::TELECONSULTATION_ANSWERS.keys},
              medical_officer_number: {"$ref" => "#/definitions/non_empty_string"},
              prescription_drugs: array_of("uuid")
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

    def activate_user
      {type: :object,
       properties: {
         id: {"$ref" => "#/definitions/uuid"},
         password: {"$ref" => "#/definitions/non_empty_string"}
       },
       required: %w[id password]}
    end

    def app_user_capability_values
      {type: :string, enum: User::APP_USER_CAPABILITY_VALUES}
    end

    def app_user_capabilities
      {type: :object,
       properties: Hash[User::APP_USER_CAPABILITIES.product([app_user_capability_values])]}
    end

    def definitions
      {timestamp: timestamp,
       uuid: uuid,
       non_empty_string: non_empty_string,
       nullable_timestamp: nullable_timestamp,
       bcrypt_password: bcrypt_password,
       blood_sugar: blood_sugar,
       blood_sugars: array_of("blood_sugar"),
       login_patient: login_patient,
       patient: patient,
       user: user,
       find_user: find_user,
       activate_user: activate_user,
       app_user_capabilities: app_user_capabilities,
       medical_officer: medical_officer,
       teleconsultation_medical_officer: teleconsultation_medical_officer,
       teleconsultation_medical_officers: array_of("teleconsultation_medical_officer"),
       teleconsultation: teleconsultation,
       teleconsultations: array_of("teleconsultation")}
    end
  end
end
