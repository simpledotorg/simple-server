class Region < ApplicationRecord
  ltree :path
  extend FriendlyId
  friendly_id :name, use: :slugged

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :path, presence: true

  belongs_to :type, class_name: "RegionType", foreign_key: "region_type_id"
  belongs_to :source, polymorphic: true, optional: true

  before_discard do
    self.path = nil
  end

  MAX_LABEL_LENGTH = 255

  def type_name
    type.name
  end

  def facilities
    case type_name
    when "Facility"
      [self]
    when "District"
      blocks = children
      facilities = blocks.map(&:children)
      pp facilities
      facilities.to_a.map(&:source)
    when "Block"
      children.map(&:source)
    else
      raise ArgumentError, "how to get facilities for #{self}"
    end
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
end
