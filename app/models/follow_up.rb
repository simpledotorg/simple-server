class FollowUp < ApplicationRecord
  belongs_to :follow_up_schedule
  belongs_to :user
  belongs_to :patient

  enum follow_up_type: {
    call: 'call'
  }, _prefix: true

  enum follow_up_result: {
    answered: 'answered'
  }

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
end