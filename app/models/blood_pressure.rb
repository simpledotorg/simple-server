class BloodPressure < ApplicationRecord
  include Mergeable
  belongs_to :patient, optional: true

  def with_payload_keys(attributes)
    key_mapping = {
      'device_created_at' => 'created_at',
      'device_updated_at' => 'updated_at'
    }.with_indifferent_access

    attributes.transform_keys { |key| key_mapping[key] || key }
  end

  def nested_hash(options = {})
    with_payload_keys(attributes).as_json
  end
end
