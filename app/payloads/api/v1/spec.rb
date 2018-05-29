module Api::V1::Spec

  ###############
  # Models

  def self.timestamp
    { type:        :string,
      format:      'date-time',
      description: 'Timestamp with millisecond precision' }
  end

  def self.nullable_timestamp
    timestamp.merge(type: [:string, 'null'])
  end

  def self.processed_since
    timestamp.merge(
      name:        'processed_since',
      description: 'The timestamp since which records have been processed by the server.
                    Use the server returned value in the next request to continue fetching records.'
    )
  end

  def self.patient_spec
    { type:       :object,
      properties: {
        id:             { type: :string, format: :uuid },
        gender:         { type: :string, enum: Patient::GENDERS },
        full_name:      { type: :string, required: true },
        status:         { type: :string, enum: Patient::STATUSES },
        date_of_birth:  { type: [:string, 'null'], format: :date },
        age:            { type:        [:integer, 'null'],
                          description: 'When age is present, age_updated_at must be present as well.' },
        age_updated_at: { '$ref' => '#/definitions/nullable_timestamp' },
        created_at:     { '$ref' => '#/definitions/timestamp' },
        updated_at:     { '$ref' => '#/definitions/timestamp' } },
      required:   %w[id gender full_name created_at updated_at status] }
  end

  def self.address_spec
    { type:       ['null', :object],
      properties: {
        id:                { type: :string, format: :uuid },
        street_address:    { type: :string },
        village_or_colony: { type: :string },
        district:          { type: :string },
        state:             { type: :string },
        country:           { type: :string },
        pin:               { type: :string },
        created_at:        { '$ref' => '#/definitions/timestamp' },
        updated_at:        { '$ref' => '#/definitions/timestamp' } },
      required:   %w[id created_at updated_at] }
  end

  def self.phone_number_spec
    { type:       :object,
      properties: {
        id:         { type: :string, format: :uuid },
        number:     { type: :string },
        phone_type: { type: :string, enum: PatientPhoneNumber::PHONE_TYPE },
        active:     { type: :boolean },
        created_at: { '$ref' => '#/definitions/timestamp' },
        updated_at: { '$ref' => '#/definitions/timestamp' } },
      required:   %w[id created_at updated_at number] }
  end

  def self.blood_pressure_spec
    { type:       :object,
      properties: {
        id:         { type: :string, format: :uuid },
        systolic:   { type: :integer },
        diastolic:  { type: :integer },
        created_at: { '$ref' => '#/definitions/timestamp' },
        updated_at: { '$ref' => '#/definitions/timestamp' },
        patient_id: { type: :string, format: :uuid } },
      required:   %w[systolic diastolic created_at updated_at patient_id]
    }
  end

  def self.blood_pressures
    { type:  :array,
      items: { '$ref' => '#/definitions/blood_pressure' } }
  end

  ###############
  # API Specs


  def self.blood_pressure_sync_from_user_request_spec
    { type:       :object,
      properties: {
        blood_pressures: { '$ref' => '#/definitions/blood_pressures' } },
      required:   %w[blood_pressures] }
  end

  def self.phone_numbers_spec
    { type:  ['null', :array],
      items: { '$ref' => '#/definitions/phone_number' } }
  end

  def self.nested_patient
    patient_spec.deep_merge(
      properties: {
        address:       { '$ref' => '#/definitions/address' },
        phone_numbers: { '$ref' => '#/definitions/phone_numbers' }, }
    )
  end

  def self.nested_patients
    { type:        :array,
      description: 'List of patients with address and phone numbers nested.',
      items:       { '$ref' => '#/definitions/nested_patient' } }
  end

  def self.sync_from_user_errors_spec
    { type:       :object,
      properties: {
        errors: {
          type:  :array,
          items: { '$ref' => '#/definitions/error_spec' } } } }
  end

  def self.error_spec
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

  def self.sync_to_user_request_spec
    [processed_since.merge(in: :query),
     { in:          :query, name: :limit, type: :integer,
       description: 'Number of record to retrieve (a.k.a batch-size)' }]
  end

  def self.patient_sync_from_user_request_spec
    { type:       :object,
      properties: {
        patients: { '$ref' => '#/definitions/nested_patients' } },
      required:   %w[patients] }
  end

  def self.patient_sync_to_user_response_spec
    { type:       :object,
      properties: {
        patients:        { '$ref' => '#/definitions/nested_patients' },
        processed_since: { '$ref' => '#/definitions/processed_since' } } }
  end

  def self.blood_pressure_sync_to_user_response_spec
    { type:       :object,
      properties: {
        blood_pressures: { '$ref' => '#/definitions/blood_pressures' },
        processed_since: { '$ref' => '#/definitions/processed_since' } } }
  end

  def self.all_definitions
    { timestamp:          timestamp,
      nullable_timestamp: nullable_timestamp,
      processed_since:    processed_since,
      patient:            patient_spec,
      address:            address_spec,
      phone_number:       phone_number_spec,
      phone_numbers:      phone_numbers_spec,
      nested_patient:     nested_patient,
      nested_patients:    nested_patients,
      blood_pressure:     blood_pressure_spec,
      blood_pressures:    blood_pressures,
      error_spec:         error_spec }
  end

  def self.swagger_info
    {
      description: I18n.t('api_description'),
      version:     'v1',
      title:       'RedApp Server',
      'x-logo'     => {
        url:             'https://static1.squarespace.com/static/59945d559f7456b755d759f2/t/59aebc5ecf81e0ac9b4b6f59/1526304079797/?format=1500w',
        backgroundColor: '#FFFFFF'
      },
      contact:     {
        email: 'eng-backend@resolvetosavelives.org'
      },
      license:     {
        name: 'MIT',
        url:  'https://github.com/resolvetosavelives/redapp-server/blob/master/LICENSE'
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
