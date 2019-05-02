class EmailAuthentication < ApplicationRecord
  devise :database_authenticatable, :invitable, :lockable, :recoverable,
         :rememberable, :timeoutable, :trackable, :validatable

  has_one :master_user_authentication, as: :authenticatable
  has_one :master_user, through: :master_user_authentication
end
