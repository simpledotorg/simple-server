class Configuration < ApplicationRecord
  validates :name, presence: true
  validates :value, presence: true

  def self.fetch(name)
    find_by(name: name)&.value
  end
end
