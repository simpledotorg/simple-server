module Api::V1::Schema
  def self.processed_since
    Models.timestamp.merge(
      name:        'processed_since',
      description: 'The timestamp since which records have been processed by the server.
                    Use the server returned value in the next request to continue fetching records.'
    )
  end

  def self.error
    { type:       :object,
      properties: {
        id:               { type:        :string,
                            format:      :uuid,
                            description: 'Id of the record with errors' },
        schema:           { type:        :array,
                            items:       { type: :string },
                            description: 'List of json schema error strings describing validation errors' },
        field_with_error: { type:  :array,
                            items: { type: :string } } } }
  end

  def self.sync_from_user_request(request_key, schema_type = request_key)
    { type:       :object,
      properties: {
        request_key => { '$ref' => "#/definitions/#{schema_type}" } },
      required:   [request_key] }
  end

  def self.sync_from_user_errors
    { type:       :object,
      properties: {
        errors: { '$ref' => '#/definitions/errors' } } }
  end

  def self.sync_to_user_request
    [processed_since.merge(in: :query),
     { in:          :query, name: :limit, type: :integer,
       description: 'Number of record to retrieve (a.k.a batch-size)' }]
  end

  def self.sync_to_user_response(response_key, schema_type = response_key)
    { type:       :object,
      properties: {
        response_key     => { '$ref' => "#/definitions/#{schema_type}" },
        :processed_since => { '$ref' => '#/definitions/processed_since' } },
      required:   [response_key, :processed_since] }
  end

  def self.patient_sync_from_user_request
    sync_from_user_request(:patients, 'nested_patients')
  end

  def self.blood_pressure_sync_from_user_request
    sync_from_user_request(:blood_pressures)
  end

  def self.prescription_drug_sync_from_user_request
    sync_from_user_request(:prescription_drugs)
  end

  def self.user_sync_from_user_request
    sync_from_user_request(:users)
  end

  def self.patient_sync_to_user_response
    sync_to_user_response(:patients, 'nested_patients')
  end

  def self.blood_pressure_sync_to_user_response
    sync_to_user_response(:blood_pressures)
  end

  def self.prescription_drug_sync_to_user_response
    sync_to_user_response(:prescription_drugs)
  end

  def self.protocol_sync_to_user_response
    sync_to_user_response(:protocols)
  end

  def self.facility_sync_to_user_response
    sync_to_user_response(:facilities)
  end

  def self.user_sync_to_user_response
    sync_to_user_response(:users)
  end

  def self.user_login_request
    { type:       :object,
      properties: {
        user: { '$ref' => '#/definitions/login_user' } },
      required:   [:user] }
  end

  def self.user_login_success_response
    { type:       :object,
      properties: {
        access_token: { type: :string },
        user:         { '$ref' => '#/definitions/user' } },
      required:   [:user] }
  end

  def self.definitions
    { error:           error,
      errors:          Models.array_of('error'),
      processed_since: processed_since }
  end

  def self.all_definitions
    definitions.merge(Models.definitions)
  end

  def self.swagger_info
    {
      description: I18n.t('api.documentation.description'),
      version:     'v1',
      title:       I18n.t('api.documentation.title'),
      'x-logo'     => {
        url:             ActionController::Base.helpers.image_path(I18n.t('api.documentation.logo.image')),
        backgroundColor: I18n.t('api.documentation.logo.background_color')
      },
      contact:     {
        email: I18n.t('api.documentation.contact.email')
      },
      license:     {
        name: I18n.t('api.documentation.license.name'),
        url:  I18n.t('api.documentation.license.url')
      }
    }
  end

  def self.security_definitions
    { basic: {
      type: :basic
    } }
  end

  def self.swagger_docs
    {
      'v1/swagger.json' => {
        swagger:     '2.0',
        basePath:    '/api/v1',
        produces:    ['application/json'],
        consumes:    ['application/json'],
        schemes:     ['https'],
        info:        swagger_info,
        paths:       {},
        definitions: all_definitions,
        securityDefinitions: security_definitions
      }
    }
  end
end
