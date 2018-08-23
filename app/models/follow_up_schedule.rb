class FollowUpSchedule < ApplicationRecord
  belongs_to :patient
  belongs_to :facility
  belongs_to :user, foreign_key: :action_by_user_id

  enum user_action: {
    scheduled: 'scheduled',
    skipped: 'skipped'
  }, _prefix: true

  enum reason_for_action: {
    not_responding: 'not_responding',
    already_visited: 'already_visited'
  }

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
end