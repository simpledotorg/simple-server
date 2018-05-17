class Patient < ApplicationRecord
  GENDERS  = %w[male female transgender].freeze
  STATUSES = %w[active dead migrated unresponsive inactive].freeze

  belongs_to :address, optional: true
  has_many :patient_phone_numbers
  has_many :phone_numbers, through: :patient_phone_numbers

  validates_presence_of :created_at, :updated_at
  validates_inclusion_of :gender, in: GENDERS
  validates_inclusion_of :status, in: STATUSES
  validate :presence_of_age

  def presence_of_age
    unless date_of_birth.present? || age_when_created.present?
      errors.add(:age, 'Either date_of_birth or age_when_created should be present')
    end
  end

  def has_errors?
    invalid? ||
      (address.present? && address.has_errors?) ||
      phone_numbers.map(&:has_errors?).any?
  end

  def errors_hash
    errors.to_hash.merge(
      id:            id,
      address:       address.present? ? address.errors_hash : nil,
      phone_numbers: phone_numbers.map(&:errors_hash)
    )
  end

  def nested_hash(options = {})
    as_json(options.merge(
      except:  %i[address_id  updated_on_server_at],
      include: { address:       { except: :updated_on_server_at },
                 phone_numbers: { except: :updated_on_server_at } }))
  end
end
