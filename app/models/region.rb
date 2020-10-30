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

  # A label is a sequence of alphanumeric characters and underscores.
  # (In C locale the characters A-Za-z0-9_ are allowed).
  # Labels must be less than 256 bytes long.
  def path_label
    slug.gsub(/\W/, "_").slice(0, MAX_LABEL_LENGTH)
  end

  def log_payload
    attrs = attributes.slice("name", "slug", "path")
    attrs["id"] = id.presence
    attrs["region_type"] = type.name
    attrs["valid"] = valid?
    attrs["errors"] = errors.full_messages.join(",") if errors.any?
    attrs.symbolize_keys
  end

  # These methods are generated on class load and updates to RegionTypes
  # will not be available until the class is reloaded.
  RegionType.all.map do |region_type|
    # Generates belongs_to type of methods to fetch a region's ancestor
    # e.g. facility.organization
    define_method(region_type.name.underscore) do
      if region_type.self_and_descendants.include?(type)
        self_and_ancestors.find_by(region_type_id: region_type)
      else
        raise NoMethodError, "undefined method #{region_type.name.underscore} for #{self} of type #{type.name}"
      end
    end

    # Generates has_many type of methods to fetch a region's descendants
    # e.g. organization.facilities
    define_method(region_type.name.pluralize.underscore) do
      if region_type.ancestors.include?(type)
        descendants.where(type: region_type)
      else
        raise NoMethodError, "undefined method #{region_type.name.pluralize.underscore} for #{self} of type #{type.name}"
      end
    end
  end
end
