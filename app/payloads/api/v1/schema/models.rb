module Api::V1::Schema::Models
  def self.timestamp
    { type: :string,
      format: 'date-time',
      description: 'Timestamp with millisecond precision.' }
  end

  def self.uuid
    { type: :string,
      format: :uuid,
      pattern: '[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}' }
  end

  def self.non_empty_string
    { type: :string,
      minLength: 1,
      description: 'This string should not be empty.' }
  end

  def self.nullable_timestamp
    timestamp.merge(type: [:string, 'null'])
  end

  def self.bcrypt_password
    { type: :string,
      pattern: '^\$[0-9a-z]{2}\$[0-9]{2}\$[A-Za-z0-9\.\/]{53}$',
      description: 'Bcrypt password digest' }
  end

  def self.array_of(type)
    { type: ['null', :array],
      items: { '$ref' => "#/definitions/#{type}" } }
  end

  def self.patient
    { type: :object,
      properties: {
        id: { '$ref' => '#/definitions/uuid' },
        gender: { type: :string, enum: Patient::GENDERS },
        full_name: { '$ref' => '#/definitions/non_empty_string' },
        status: { type: :string, enum: Patient::STATUSES },
        date_of_birth: { type: [:string, 'null'], format: :date },
        age: { type: [:integer, 'null'],
               description: 'When age is present, age_updated_at must be present as well.' },
        age_updated_at: { '$ref' => '#/definitions/nullable_timestamp' },
        created_at: { '$ref' => '#/definitions/timestamp' },
        updated_at: { '$ref' => '#/definitions/timestamp' } },
      required: %w[id gender full_name created_at updated_at status] }
  end

  def self.address
    { type: ['null', :object],
      properties: {
        id: { '$ref' => '#/definitions/uuid' },
        street_address: { type: :string },
        village_or_colony: { type: :string },
        district: { type: :string },
        state: { type: :string },
        country: { type: :string },
        pin: { type: :string },
        created_at: { '$ref' => '#/definitions/timestamp' },
        updated_at: { '$ref' => '#/definitions/timestamp' } },
      required: %w[id created_at updated_at] }
  end

  def self.phone_number
    { type: :object,
      properties: {
        id: { '$ref' => '#/definitions/uuid' },
        number: { '$ref' => '#/definitions/non_empty_string' },
        phone_type: { type: :string, enum: PatientPhoneNumber::PHONE_TYPE },
        active: { type: :boolean },
        created_at: { '$ref' => '#/definitions/timestamp' },
        updated_at: { '$ref' => '#/definitions/timestamp' } },
      required: %w[id created_at updated_at number] }
  end

  def self.nested_patient
    patient.deep_merge(
      properties: {
        address: { '$ref' => '#/definitions/address' },
        phone_numbers: { '$ref' => '#/definitions/phone_numbers' }, },
      description: 'Patient with address and phone numbers nested.',
    )
  end

  def self.blood_pressure
    { type: :object,
      properties: {
        id: { '$ref' => '#/definitions/uuid' },
        systolic: { type: :integer },
        diastolic: { type: :integer },
        created_at: { '$ref' => '#/definitions/timestamp' },
        updated_at: { '$ref' => '#/definitions/timestamp' },
        patient_id: { '$ref' => '#/definitions/uuid' },
        facility_id: { '$ref' => '#/definitions/uuid' },
        user_id: { '$ref' => '#/definitions/uuid' } },
      required: %w[systolic diastolic created_at updated_at patient_id facility_id user_id]
    }
  end

  def self.facility
    {
      type: :object,
      properties: {
        id: { '$ref' => '#/definitions/uuid' },
        created_at: { '$ref' => '#/definitions/timestamp' },
        updated_at: { '$ref' => '#/definitions/timestamp' },
        name: { '$ref' => '#/definitions/non_empty_string' },
        street_address: { type: :string },
        village_or_colony: { type: :string },
        district: { '$ref' => '#/definitions/non_empty_string' },
        state: { '$ref' => '#/definitions/non_empty_string' },
        country: { '$ref' => '#/definitions/non_empty_string' },
        pin: { type: :string },
        facility_type: { type: :string }
      },
      required: %w[id name district state country]
    }
  end

  def self.protocol_drug
    { type: :object,
      properties: {
        id: { '$ref' => '#/definitions/uuid' },
        created_at: { '$ref' => '#/definitions/timestamp' },
        updated_at: { '$ref' => '#/definitions/timestamp' },
        protocol_id: { '$ref' => '#/definitions/uuid' },
        rxnorm_code: { type: :string },
        dosage: { type: :string },
        name: { type: :string } },
      required: %w[id dosage name protocol_id] }
  end

  def self.protocol
    { type: :object,
      properties: {
        id: { '$ref' => '#/definitions/uuid' },
        created_at: { '$ref' => '#/definitions/timestamp' },
        updated_at: { '$ref' => '#/definitions/timestamp' },
        name: { type: :string },
        follow_up_days: { type: :integer },
        protocol_drugs: { '$ref' => '#/definitions/protocol_drugs' } },
      required: %w[id name protocol_drugs] }
  end

  def self.prescription_drug
    { type: :object,
      properties: {
        id: { '$ref' => '#/definitions/uuid' },
        created_at: { '$ref' => '#/definitions/timestamp' },
        updated_at: { '$ref' => '#/definitions/timestamp' },
        name: { '$ref' => '#/definitions/non_empty_string' },
        dosage: { type: :string },
        rxnorm_code: { type: :string },
        is_protocol_drug: { type: :boolean },
        is_deleted: { type: :boolean },
        patient_id: { '$ref' => '#/definitions/uuid' },
        facility_id: { '$ref' => '#/definitions/uuid' }
      },
      required: %w[id created_at updated_at name is_protocol_drug is_deleted patient_id facility_id] }
  end

  def self.user
    { type: :object,
      properties: {
        id: { '$ref' => '#/definitions/uuid' },
        created_at: { '$ref' => '#/definitions/timestamp' },
        updated_at: { '$ref' => '#/definitions/timestamp' },
        full_name: { '$ref' => '#/definitions/non_empty_string' },
        phone_number: { '$ref' => '#/definitions/non_empty_string' },
        password_digest: { '$ref' => '#/definitions/bcrypt_password' },
        facility_id: { '$ref' => '#/definitions/uuid' } },
      required: %w[id created_at updated_at full_name phone_number password_digest facility_id] }
  end

  def self.login_user
    { type: :object,
      properties: {
        phone_number: { '$ref' => '#/definitions/non_empty_string' },
        password: { '$ref' => '#/definitions/non_empty_string' },
        otp: { '$ref' => '#/definitions/non_empty_string' } },
      required: %w[phone_number password otp] }
  end

  def self.register_user
    { type: :object,
      properties: {
        full_name: { '$ref' => '#/definitions/non_empty_string' },
        phone_number: { '$ref' => '#/definitions/non_empty_string' },
        password: { '$ref' => '#/definitions/non_empty_string' },
        password_confirmation: { '$ref' => '#/definitions/non_empty_string' },
        facility_id: { '$ref' => '#/definitions/uuid' },
        created_at: { '$ref' => '#/definitions/timestamp' },
        updated_at: { '$ref' => '#/definitions/timestamp' }
      },
      required: %w[full_name phone_number password password_confirmation facility_id created_at updated_at]
    }
  end

  def self.definitions
    { timestamp: timestamp,
      uuid: uuid,
      non_empty_string: non_empty_string,
      nullable_timestamp: nullable_timestamp,
      bcrypt_password: bcrypt_password,
      patient: patient,
      address: address,
      phone_number: phone_number,
      phone_numbers: array_of('phone_number'),
      nested_patient: nested_patient,
      nested_patients: array_of('nested_patient'),
      blood_pressure: blood_pressure,
      blood_pressures: array_of('blood_pressure'),
      facility: facility,
      facilities: array_of('facility'),
      protocol_drug: protocol_drug,
      protocol_drugs: array_of('protocol_drug'),
      protocol: protocol,
      protocols: array_of('protocol'),
      prescription_drug: prescription_drug,
      prescription_drugs: array_of('prescription_drug'),
      user: user,
      users: array_of('user'),
      login_user: login_user }
  end
end
