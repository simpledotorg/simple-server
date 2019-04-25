class PhoneNumberAuthentication < ApplicationRecord
  has_many :master_user_authentication, as: :authenticatable
end