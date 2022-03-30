class Api::V4::Schema
  class << self
    def process_token
      {name: "process_token",
       type: :string,
       format: "byte",
       description: "Token containing all the information needed to process batch requests from the user"}
    end

    def error
      {type: :object,
       properties: {
         id: {type: :string,
              format: :uuid,
              description: "Id of the record with errors"},
         schema: {type: :array,
                  items: {type: :string},
                  description: "List of json schema error strings describing validation errors"},
         field_with_error: {type: :array,
                            items: {type: :string}}
       }}
    end

    def sync_from_user_request(request_key, schema_type = request_key)
      {type: :object,
       properties: {
         request_key => {"$ref" => "#/definitions/#{schema_type}"}
       },
       required: [request_key]}
    end

    def sync_from_user_errors
      {type: :object,
       properties: {
         errors: {"$ref" => "#/definitions/errors"}
       }}
    end

    def sync_to_user_request
      [process_token.merge(in: :query),
        {in: :query, name: :limit, type: :integer,
         description: "Number of record to retrieve (a.k.a batch-size)"}]
    end

    def sync_to_user_response(response_key, schema_type = response_key)
      {type: :object,
       properties: {
         response_key => {"$ref" => "#/definitions/#{schema_type}"},
         :process_token => {"$ref" => "#/definitions/process_token"}
       },
       required: [response_key, :process_token]}
    end

    def blood_sugar_sync_from_user_request
      sync_from_user_request(:blood_sugars)
    end

    def blood_sugar_sync_to_user_response
      sync_to_user_response(:blood_sugars)
    end

    def facility_medical_officers_sync_to_user_response
      {
        type: :object,
        properties: {
          facility_medical_officers: {"$ref" => "#/definitions/facility_medical_officers"}
        }
      }
    end

    def teleconsultation_sync_from_user_request
      sync_from_user_request(:teleconsultations)
    end

    def patient_activate_request
      {
        type: :object,
        properties: {
          passport_id: {"$ref" => "#/definitions/uuid"}
        }
      }
    end

    def patient_login_request
      {
        type: :object,
        properties: {
          passport_id: {"$ref" => "#/definitions/uuid"},
          otp: {"$ref" => "#/definitions/non_empty_string"}
        }
      }
    end

    def patient_login_response
      {
        type: :object,
        properties: {
          patient: {"$ref" => "#/definitions/login_patient"}
        }
      }
    end

    def lookup_request
      {
        type: :object,
        properties: {
          identifier: {
            type: :string,
            description: "Full identifier string of the BP Passport, or other supported identifier type"
          }
        },
        required: [:identifier]
      }
    end

    def lookup_response
      {
        type: :object,
        properties: {
          patients: {"$ref" => "#/definitions/lookup_patients"}
        }
      }
    end

    def patient_response
      {
        type: :object,
        properties: {
          patient: {"$ref" => "#/definitions/patient"}
        }
      }
    end

    def user_find_request
      {type: :object,
       properties: {phone_number: {"$ref" => "#/definitions/non_empty_string"}},
       required: %i[phone_number]}
    end

    def user_find_response
      {type: :object,
       properties: {
         user: {"$ref" => "#/definitions/find_user"}
       }}
    end

    def user_activate_request
      {type: :object,
       properties: {user: {"$ref" => "#/definitions/activate_user"}},
       required: %i[user]}
    end

    def user_activate_response
      {type: :object,
       properties: {user: {"$ref" => "#/definitions/user"}},
       required: %i[user]}
    end

    def user_activate_error
      {type: :object,
       properties: {
         errors: {
           type: :object,
           properties: {
             user: {
               type: :array,
               items: {type: :string},
               description: "List of descriptive error strings"
             }
           }
         }
       },
       required: %i[errors]}
    end

    def user_me_response
      {type: :object,
       properties: {user: {"$ref" => "#/definitions/user"}},
       required: %i[user]}
    end

    def facility_teleconsultations_response
      {type: :object,
       properties: {teleconsultation_phone_number: {type: [:string, "null"]},
                    teleconsultation_phone_numbers: {type: :array,
                                                     items: {type: :object,
                                                             properties: {phone_number: {type: :string}},
                                                             required: %i[phone_number]}}},
       required: %i[teleconsultation_phone_number teleconsultation_phone_numbers]}
    end

    def medication_sync_to_user_response
      sync_to_user_response(:medications)
    end

    def call_result_sync_from_user_request
      sync_from_user_request(:call_results)
    end

    def states_response
      {type: :object,
       properties: {states: {type: :array,
                             items: {type: :object,
                                     properties: {name: {type: :string}}}}},
       description: "List of available state names"}
    end

    def definitions
      {error: error,
       errors: Api::V4::Models.array_of("error"),
       process_token: process_token}
    end

    def all_definitions
      definitions.merge(Api::V4::Models.definitions)
    end
  end
end
