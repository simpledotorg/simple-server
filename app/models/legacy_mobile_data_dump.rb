class LegacyMobileDataDump < ActiveRecord::Base
  belongs_to :user

  validates :raw_payload, presence: true
  validates :dump_date, presence: true
end
