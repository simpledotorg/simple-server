class EmailAuthentication < ApplicationRecord
  include PgSearch::Model

  devise :database_authenticatable, :invitable, :lockable, :recoverable,
    :rememberable, :timeoutable, :trackable, :validatable, validate_on_invite: true

  has_one :user_authentication, as: :authenticatable
  has_one :user, through: :user_authentication

  pg_search_scope :search_by_email, against: [:email], using: {tsearch: {any_word: true}}

  delegate :full_name, :resources, :role, :organization, to: :user, allow_nil: true

  validates :password, presence: true, on: :create
  validates :password,
    length: {in: Devise.password_length, message: "must be between 10 and 128 characters"},
    allow_nil: true
  validates :password,
    format: {with: /(?=.*[a-z])/, message: "must contain at least one lower case letter"},
    allow_nil: true
  validates :password,
    format: {with: /(?=.*[A-Z])/, message: "must contain at least one upper case letter"},
    allow_nil: true
  validates :password,
    format: {with: /(?=.*\d)/, message: "must contain at least one number"},
    allow_nil: true

  after_validation :strip_unnecessary_errors

  private

  # We only want to display one error message to the user, so if we get multiple
  # errors clear out all errors and present our nice message to the user.
  def strip_unnecessary_errors
    if errors[:password].any? && errors[:password].size > 1
      errors.delete(:password)
      errors.add(:password, I18n.translate("errors.messages.password.password_strength"))
    end
  end
end
