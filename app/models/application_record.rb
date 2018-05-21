class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.updated_on_server_since(timestamp)
    self
      .where('updated_on_server_at >= ?', timestamp)
      .order(:updated_on_server_at)
  end
end