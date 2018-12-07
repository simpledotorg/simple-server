class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.updated_on_server_since(timestamp, number_of_records = nil)
    where("#{self.table_name}.updated_at >= ?", timestamp)
      .order(:updated_at)
      .limit(number_of_records)
  end
end
