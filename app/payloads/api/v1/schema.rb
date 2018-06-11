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

  def self.patient_sync_from_user_request
    { type:       :object,
      properties: {
        patients: { '$ref' => '#/definitions/nested_patients' } },
      required:   %w[patients] }
  end

  def self.blood_pressure_sync_from_user_request
    { type:       :object,
      properties: {
        blood_pressures: { '$ref' => '#/definitions/blood_pressures' } },
      required:   %w[blood_pressures] }
  end

  def self.prescription_drugs_sync_from_user_request
    { type:       :object,
      properties: {
        prescription_drugs: { '$ref' => '#/definitions/prescription_drugs' } },
      required:   %w[prescription_drugs] }
  end

  def self.users_sync_from_user_request
    { type:       :object,
      properties: {
        users: { '$ref' => '#/definitions/users' } },
      required:   %w[users] }
  end

  def self.sync_from_user_errors
    { type:       :object,
      properties: {
        errors: {
          type:  :array,
          items: { '$ref' => '#/definitions/error' } } } }
  end

  def self.sync_to_user_request
    [processed_since.merge(in: :query),
     { in:          :query, name: :limit, type: :integer,
       description: 'Number of record to retrieve (a.k.a batch-size)' }]
  end

  def self.patient_sync_to_user_response
    { type:       :object,
      properties: {
        patients:        { '$ref' => '#/definitions/nested_patients' },
        processed_since: { '$ref' => '#/definitions/processed_since' } },
      required:   %w[patients processed_since] }
  end

  def self.blood_pressure_sync_to_user_response
    { type:       :object,
      properties: {
        blood_pressures: { '$ref' => '#/definitions/blood_pressures' },
        processed_since: { '$ref' => '#/definitions/processed_since' } },
      required:   %w[blood_pressures processed_since] }
  end

  def self.prescription_drug_sync_to_user_response
    { type:       :object,
      properties: {
        prescription_drugs: { '$ref' => '#/definitions/prescription_drugs' },
        processed_since:    { '$ref' => '#/definitions/processed_since' } },
      required:   %w[prescription_drugs processed_since] }
  end

  def self.protocol_sync_to_user_response
    { type:       :object,
      properties: {
        protocols:       { '$ref' => '#/definitions/protocols' },
        processed_since: { '$ref' => '#/definitions/processed_since' } },
      required:   %w[protocols processed_since] }
  end

  def self.facility_sync_to_user_response
    {
      type:       :object,
      properties: {
        facilities:      { '$ref' => '#/definitions/facilities' },
        processed_since: { '$ref' => '#/definitions/processed_since' }
      },
      required:   %w[facilities processed_since]
    }
  end

  def self.user_sync_to_user_response
    {
      type:       :object,
      properties: {
        facilities:      { '$ref' => '#/definitions/users' },
        processed_since: { '$ref' => '#/definitions/processed_since' }
      },
      required:   %w[users processed_since]
    }
  end

  def self.definitions
    { error:           error,
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
        definitions: all_definitions
      }
    }
  end
end
