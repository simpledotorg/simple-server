class RegionKind < ApplicationRecord
  ltree :path

  validates :name, presence: true, uniqueness: true
  validates :path, presence: true

  attr_accessor :parent

  before_validation :set_path, if: :parent

  def set_path
    self.path = "#{parent.path}.#{name}"
  end
end
