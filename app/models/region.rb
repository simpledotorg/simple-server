class Region < ApplicationRecord
  ltree :path
  extend FriendlyId
  friendly_id :name, use: :slugged

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :path, presence: true
  validates :region_type, presence: true

  belongs_to :source, polymorphic: true, optional: true

  before_discard do
    self.path = nil
  end

  MAX_LABEL_LENGTH = 255

  REGION_TYPES = %w[root organization state district block facility]
  enum region_type: REGION_TYPES.map(&:to_sym).zip(REGION_TYPES).to_h

  # A label is a sequence of alphanumeric characters and underscores.
  # (In C locale the characters A-Za-z0-9_ are allowed).
  # Labels must be less than 256 bytes long.
  def name_to_path_label
    name.gsub(/\W/, "_").slice(0, MAX_LABEL_LENGTH)
  end

  def log_payload
    attrs = attributes.slice("name", "slug", "path")
    attrs["id"] = id.presence
    attrs["region_type"] = region_type
    attrs["valid"] = valid?
    attrs["errors"] = errors.full_messages.join(",") if errors.any?
    attrs.symbolize_keys
  end

  def ancestor_types(region_type)
    REGION_TYPES.split(region_type).first
  end

  def descendant_types(region_type)
    REGION_TYPES.split(region_type).second
  end

  def self_and_descendant_types(region_type)
    [region_type] + descendant_types(region_type)
  end

  def self_and_ancestor_types(region_type)
    ancestor_types(region_type) + [region_type]
  end

  REGION_TYPES.map do |region_type|
    # Generates belongs_to type of methods to fetch a region's ancestor
    # e.g. facility.organization
    define_method(region_type.underscore) do
      if self_and_descendant_types(region_type).include?(self.region_type)
        self_and_ancestors.find_by(region_type: region_type)
      else
        raise NoMethodError, "undefined method #{region_type.underscore} for #{self} of type #{self.region_type}"
      end
    end

    # Generates has_many type of methods to fetch a region's descendants
    # e.g. organization.facilities
    define_method(region_type.pluralize.underscore) do
      if ancestor_types(region_type).include?(self.region_type)
        descendants.where(region_type: region_type)
      else
        raise NoMethodError, "undefined method #{region_type.pluralize.underscore} for #{self} of type #{self.region_type}"
      end
    end
  end
end
