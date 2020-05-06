class EmailAuthentication < ApplicationRecord
  devise :database_authenticatable, :invitable, :lockable, :recoverable,
         :rememberable, :timeoutable, :trackable, :validatable, validate_on_invite: true

  has_one :user_authentication, as: :authenticatable
  has_one :user, through: :user_authentication

  delegate :full_name, :resources, :role, :organization, to: :user, allow_nil: true

  validates :password, password_strength: {use_dictionary: true}, allow_nil: true

end
