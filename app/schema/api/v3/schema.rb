# frozen_string_literal: true

class Api::V3::Schema
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

    def patient_sync_from_user_request
      sync_from_user_request(:patients, "nested_patients")
    end

    def blood_pressure_sync_from_user_request
      sync_from_user_request(:blood_pressures)
    end

    def blood_sugar_sync_from_user_request
      sync_from_user_request(:blood_sugars)
    end

    def prescription_drug_sync_from_user_request
      sync_from_user_request(:prescription_drugs)
    end

    def communication_sync_from_user_request
      sync_from_user_request(:communication)
    end

    def appointment_sync_from_user_request
      sync_from_user_request(:appointments)
    end

    def medical_history_sync_from_user_request
      sync_from_user_request(:medical_histories)
    end

    def encounter_sync_from_user_request
      sync_from_user_request(:encounters)
    end

    def patient_sync_to_user_response
      sync_to_user_response(:patients, "nested_patients")
    end

    def blood_pressure_sync_to_user_response
      sync_to_user_response(:blood_pressures)
    end

    def blood_sugar_sync_to_user_response
      sync_to_user_response(:blood_sugars)
    end

    def prescription_drug_sync_to_user_response
      sync_to_user_response(:prescription_drugs)
    end

    def protocol_sync_to_user_response
      sync_to_user_response(:protocols)
    end

    def facility_sync_to_user_response
      sync_to_user_response(:facilities)
    end

    def communication_sync_to_user_response
      sync_to_user_response(:communications)
    end

    def appointment_sync_to_user_response
      sync_to_user_response(:appointments)
    end

    def medical_history_sync_to_user_response
      sync_to_user_response(:medical_histories)
    end

    def encounter_sync_to_user_response
      sync_to_user_response(:encounters)
    end

    def user_login_request
      {type: :object,
       properties: {
         user: {"$ref" => "#/definitions/login_user"}
       },
       required: [:user]}
    end

    def user_registration_response
      {type: :object,
       properties: {
         access_token: {"$ref" => "#/definitions/non_empty_string"},
         user: {"$ref" => "#/definitions/user"}
       },
       required: %i[user access_token]}
    end

    def user_login_success_response
      user_registration_response
    end

    def user_registration_request
      {type: :object,
       properties: {
         user: {"$ref" => "#/definitions/user"}
       },
       required: %i[user]}
    end

    def user_reset_password_request
      {type: :object,
       properties: {
         password_digest: {"$ref" => "#/definitions/bcrypt_password"}
       },
       required: %i[password_digest]}
    end

    def definitions
      {error: error,
       errors: Api::V3::Models.array_of("error"),
       process_token: process_token}
    end

    def all_definitions
      definitions.merge(Api::V3::Models.definitions)
    end
  end
end
