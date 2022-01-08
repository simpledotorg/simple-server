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
    format: {with: /(?=.*[a-z])/, error: :needs_lower, message: "must contain at least one lower case letter"},
    allow_nil: true
  validates :password,
    format: {with: /(?=.*[A-Z])/, error: :needs_upper, message: "must contain at least one upper case letter"},
    allow_nil: true
  validates :password,
    format: {with: /(?=.*\d)/, error: :needs_number, message: "must contain at least one number"},
    allow_nil: true

  def self.generate_password
    lower = Array("a".."z").sample
    upper = Array("A".."Z").sample
    number = SecureRandom.random_number(1).to_s
    SecureRandom.base64(16) + lower + upper + number
  end

  def invalidate_all_sessions!
    update_attribute(:session_token, SecureRandom.hex)
  end

  def authenticatable_salt
    "#{super}#{session_token}"
  end
end
