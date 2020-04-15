class Api::V4::Schema
  class << self
    def process_token
      { name: 'process_token',
        type: :string,
        format: 'byte',
        description: 'Token containing all the information needed to process batch requests from the user' }
    end

    def error
      { type: :object,
        properties: {
          id: { type: :string,
                format: :uuid,
                description: 'Id of the record with errors' },
          schema: { type: :array,
                    items: { type: :string },
                    description: 'List of json schema error strings describing validation errors' },
          field_with_error: { type: :array,
                              items: { type: :string } } } }
    end

    def sync_from_user_request(request_key, schema_type = request_key)
      { type: :object,
        properties: {
          request_key => { '$ref' => "#/definitions/#{schema_type}" } },
        required: [request_key] }
    end

    def sync_from_user_errors
      { type: :object,
        properties: {
          errors: { '$ref' => '#/definitions/errors' } } }
    end

    def sync_to_user_request
      [process_token.merge(in: :query),
       { in: :query, name: :limit, type: :integer,
         description: 'Number of record to retrieve (a.k.a batch-size)' }]
    end

    def sync_to_user_response(response_key, schema_type = response_key)
      { type: :object,
        properties: {
          response_key => { '$ref' => "#/definitions/#{schema_type}" },
          :process_token => { '$ref' => '#/definitions/process_token' } },
        required: [response_key, :process_token] }
    end

    def blood_sugar_sync_from_user_request
      sync_from_user_request(:blood_sugars)
    end

    def blood_sugar_sync_to_user_response
      sync_to_user_response(:blood_sugars)
    end

    def patient_request_otp_request
      { type: :object,
        properties: {
          passport_id: { '$ref' => '#/definitions/uuid' } } }
    end

    def patient_activate_request
      { type: :object,
        properties: {
          passport_id: { '$ref' => '#/definitions/uuid' },
          otp: { '$ref' => '#/definitions/non_empty_string' }, } }
    end

    def patient_activate_response
      { type: :object,
        properties: {
          access_token: { '$ref' => '#/definitions/non_empty_string' },
          patient_id: { '$ref' => '#/definitions/uuid' } } }
    end

    def user_find_request
      { type: :object,
        properties: { phone_number: { '$ref' => '#/definitions/non_empty_string'} },
        required: %i[phone_number] }
    end

    def user_find_response
      { type: :object,
        properties: {
          user: { '$ref' => '#/definitions/find_user' } } }
    end

    def user_activate_request
      { type: :object,
        properties: { user: { '$ref' => '#/definitions/activate_user'} },
        required: %i[user] }
    end

    def user_activate_response
      { type: :object,
        properties: { user: { '$ref' => '#/definitions/user' } },
        required: %i[user] }
    end

    def user_activate_error
      { type: :object,
        properties: {
          errors: {
            type: :object,
            properties: {
              user: {
                type: :array,
                items: { type: :string },
                description: 'List of descriptive error strings'
              }
            }
          }
        } ,
        required: %i[errors] }
    end

    def user_me_response
      { type: :object,
        properties: { user: { '$ref' => '#/definitions/user' } },
        required: %i[user] }
    end

    def definitions
      { error: error,
        errors: Api::V4::Models.array_of('error'),
        process_token: process_token }
    end

    def all_definitions
      definitions.merge(Api::V4::Models.definitions)
    end
  end
end
