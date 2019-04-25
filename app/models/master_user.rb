class MasterUser< ApplicationRecord
  has_many :master_user_authentications

  validates :full_name, presence: true
end