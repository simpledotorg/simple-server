class FollowUp < ApplicationRecord
  include Mergeable

  belongs_to :follow_up_schedule, optional: true
  belongs_to :patient, optional: true
  belongs_to :user

  enum follow_up_type: {
    call: 'call'
  }, _prefix: true

  enum follow_up_result: {
    answered: 'answered',
    did_not_answer: 'did_not_answer'
  }

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
end