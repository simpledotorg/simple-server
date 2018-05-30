class Patient < ApplicationRecord
  include Mergeable

  GENDERS  = %w[male female transgender].freeze
  STATUSES = %w[active dead migrated unresponsive inactive].freeze

  belongs_to :address, optional: true
  has_many :phone_numbers, class_name: 'PatientPhoneNumber'

  validates_associated :address, if: :address
  validates_associated :phone_numbers, if: :phone_numbers

  def with_payload_keys(attributes)
    key_mapping = {
      'device_created_at' => 'created_at',
      'device_updated_at' => 'updated_at'
    }.with_indifferent_access

    attributes.transform_keys { |key| key_mapping[key] || key }
  end

  def nested_hash(options = {})
    with_payload_keys(attributes)
      .except('address_id')
      .merge(
        'address'       => with_payload_keys(address.attributes),
        'phone_numbers' => phone_numbers.map { |phone_number| with_payload_keys(phone_number.attributes).except('patient_id') }
      )
      .as_json
  end
end
