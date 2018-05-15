module Spec

  ###############
  # Models

  def patient_spec
    { type:       :object,
      properties: { id:               { type: :string, format: :uuid },
                    gender:           { type: :string, enum: Patient::GENDERS },
                    full_name:        { type: :string },
                    status:           { type: :string, enum: Patient::STATUSES },
                    date_of_birth:    { type: :string, format: :date },
                    age_when_created: { type: :integer },
                    created_at:       { type: :string, format: 'date-time' },
                    updated_at:       { type: :string, format: 'date-time' } },
      required:   %w[id gender full_name created_at updated_at status] }
  end

  def address_spec
    { type:       :object,
      properties: { id:             { type: :string, format: :uuid },
                    street_address: { type: :string },
                    colony:         { type: :string },
                    village:        { type: :string },
                    district:       { type: :string },
                    state:          { type: :string },
                    country:        { type: :string },
                    pin:            { type: :string },
                    created_at:     { type: :string, format: 'date-time' },
                    updated_at:     { type: :string, format: 'date-time' } },
      required:   %w[id created_at updated_at] }
  end

  def phone_number_spec
    { type:       :object,
      properties: { id:         { type: :string, format: :uuid },
                    number:     { type: :string },
                    phone_type: { type: :string, enum: PhoneNumber::PHONE_TYPE },
                    active:     { type: :boolean },
                    created_at: { type: :string, format: 'date-time' },
                    updated_at: { type: :string, format: 'date-time' } },
      required:   %w[id created_at updated_at] }
  end


  ###############
  # API Specs

  def phone_numbers_spec
    { type:  :array,
      items: { '$ref' => '#/definitions/phone_number' } }
  end

  def patient_sync_request_spec
    { type:       :object,
      properties: { patients:
                      { type:  :array,
                        items: patient_spec.deep_merge(
                          properties: { address:       { '$ref' => '#/definitions/address' },
                                        phone_numbers: { '$ref' => '#/definitions/phone_numbers' } }
                        ) } },
      required:   %w[patients] }
  end

  def error_spec
    { type:       :object,
      properties: { id:               { type: :string, format: :uuid },
                    field_with_error: { type:  :array,
                                        items: { type: :string } } },
      required:   %w[id] }
  end

  def patient_error_spec
    { type:       :object,
      properties: { id:            { type: :string, format: :uuid },
                    address:       { '$ref' => '#/definitions/error_spec' },
                    phone_numbers: { type:  :array,
                                     items: { '$ref' => '#/definitions/error_spec' } } },
      required:   %w[id] }
  end

  def patient_sync_errors_spec
    { type:       :object,
      properties: { errors: { type:  :array,
                              items: { '$ref' => '#/definitions/patient_error_spec' } } } }
  end

  def all_definitions
    { patient:            patient_spec,
      address:            address_spec,
      phone_number:       phone_number_spec,
      phone_numbers:      phone_numbers_spec,
      error_spec:         error_spec,
      patient_error_spec: patient_error_spec }
  end

end
