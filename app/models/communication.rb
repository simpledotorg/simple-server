class Communication < ApplicationRecord
  include Mergeable

  belongs_to :appointment, optional: true
  belongs_to :patient, optional: true
  belongs_to :user

  enum communication_type: {
    manual_call: 'manual_call',
    voip_call: 'voip_call',
  }, _prefix: true

  enum communication_result: {
    unavailable: 'unavailable',
    unreachable: 'unreachable',
    successful: 'successful'
  }

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
end