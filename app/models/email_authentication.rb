class EmailAuthentication < ApplicationRecord
  EXAMPLE_PASSPHRASE = "logic finite eager ratio"

  devise :database_authenticatable, :invitable, :lockable, :recoverable,
         :rememberable, :timeoutable, :trackable, :validatable, validate_on_invite: true

  has_one :user_authentication, as: :authenticatable
  has_one :user, through: :user_authentication

  delegate :full_name, :resources, :role, :organization, to: :user, allow_nil: true

  validates :password, password_strength: {use_dictionary: true}, allow_nil: true
  validate :cannot_use_example_password

  private

  def cannot_use_example_password
    return unless password.present?
    if password == EXAMPLE_PASSPHRASE
      errors.add(:password, "cannot match the example password")
    end
  end

end
