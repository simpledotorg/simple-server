class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  validates_presence_of :device_created_at, :device_updated_at

  def self.updated_on_server_since(timestamp, number_of_records = nil)
    where('updated_at >= ?', timestamp)
      .order(:updated_at)
      .limit(number_of_records)
  end
end