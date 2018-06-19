class Admin < ApplicationRecord
  devise :database_authenticatable, :lockable, :invitable, :recoverable,
         :rememberable, :timeoutable, :trackable, :validatable
end
