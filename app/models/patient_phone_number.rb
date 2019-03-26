class PatientPhoneNumber < ApplicationRecord
  include Mergeable

  PHONE_TYPE = %w[mobile landline].freeze

  belongs_to :patient

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  def self.first
    order(device_created_at: :asc).first
  end

  def self.last
    order(device_created_at: :asc).last
  end
end
