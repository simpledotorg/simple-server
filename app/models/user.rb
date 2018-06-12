class User < ApplicationRecord
  include Mergeable

  has_secure_password

  belongs_to :facility
  has_many :blood_pressures
  has_many :patients, through: :blood_pressures

  validates :full_name, presence: true
  validates :phone_number, presence: true
  validate :presence_of_password
  validates :password, allow_blank: true, length: { is: 4 }, format: { with: /[0-9]/, message: 'only allows numbers' }

  def presence_of_password
    unless password_digest.present? || password.present?
      errors.add(:age, 'Either password_digest or password should be present')
    end
  end
end
