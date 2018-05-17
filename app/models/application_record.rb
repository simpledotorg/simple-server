class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  before_save :set_updated_on_server_at

  def set_updated_on_server_at
    self.updated_on_server_at = Time.now unless self.updated_on_server_at.present?
  end

end