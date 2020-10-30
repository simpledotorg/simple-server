class Region < ApplicationRecord
  MAX_LABEL_LENGTH = 255

  ltree :path
  extend FriendlyId
  friendly_id :name, use: :slugged

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :path, presence: true

  belongs_to :type, class_name: "RegionType", foreign_key: "region_type_id"
  belongs_to :source, polymorphic: true, optional: true

  attr_writer :parent

  before_validation :set_path
  after_save :update_children, if: :saved_change_to_name?
  before_discard :remove_path

  def update_children
    children.update(parent: self)
  end

  # A label is a sequence of alphanumeric characters and underscores.
  # (In C locale the characters A-Za-z0-9_ are allowed).
  # Labels must be less than 256 bytes long.
  def name_to_path_label
    name.gsub(/\W/, "_").slice(0, MAX_LABEL_LENGTH)
  end

  def log_payload
    attrs = attributes.slice("name", "slug", "path")
    attrs["id"] = id.presence
    attrs["region_type"] = type.name
    attrs["valid"] = valid?
    attrs["errors"] = errors.full_messages.join(",") if errors.any?
    attrs.symbolize_keys
  end

  def set_path
    self.path = if @parent
      "#{@parent.path}.#{name_to_path_label}"
    elsif parent
      "#{parent.path}.#{name_to_path_label}"
    end
  end

  def remove_path
    self.path = nil
  end
end
