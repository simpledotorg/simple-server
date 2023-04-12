class DownloadApiToken < ApplicationRecord
  after_initialize :generate_access_token
  belongs_to :facility
  def generate_access_token
    self.access_token = SecureRandom.hex(32)
  end
end