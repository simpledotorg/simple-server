class AuditLog < ApplicationRecord
  ACTIONS                = %w[fetch create update login invalid touch].freeze
  MERGE_STATUS_TO_ACTION = {
    invalid: 'invalid',
    new:     'create',
    updated: 'update',
    old:     'touch'
  }.freeze


  belongs_to :user
  belongs_to :auditable, polymorphic: true

  validates :action, presence: true
  validates :auditable_type, presence: true
  validates :auditable_id, presence: true

  def self.merge_log(user, record)
    create(
      user:           user,
      auditable_type: record.class.to_s,
      auditable_id:   record.id,
      action:         MERGE_STATUS_TO_ACTION[record.merge_status])
  end

  def self.fetch_log(user, record)
    create(
      user:           user,
      auditable_type: record.class.to_s,
      auditable_id:   record.id,
      action:         'fetch')
  end

  def self.login_log(user)
    create(
      user:           user,
      auditable_type: 'User',
      auditable_id:   user.id,
      action:         'login')
  end
end
