class Patient < ApplicationRecord
  GENDERS = %w[male female transgender].freeze
  STATUSES = %w[active dead migrated unresponsive inactive]

  belongs_to :address, optional: true
  has_and_belongs_to_many :phone_numbers

  validates_presence_of :created_at, :updated_at
  validates_inclusion_of :gender, in: GENDERS
  validates_inclusion_of :status, in: STATUSES
  validate :presence_of_age

  def presence_of_age
    unless date_of_birth.present? || age_when_created.present?
      errors.add(:age, "Either date_of_birth or age_when_created should be present")
    end
  end
end