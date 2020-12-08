class Region < ApplicationRecord
  MAX_LABEL_LENGTH = 255

  ltree :path
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :path, presence: true, uniqueness: true
  validates :region_type, presence: true

  belongs_to :source, polymorphic: true, optional: true
  auto_strip_attributes :name, squish: true, upcase_first: true

  # To set a new path for a Region, assign the parent region via `reparent_to`, and the before_validation
  # callback will assign the new path.
  attr_accessor :reparent_to
  before_validation :initialize_path, if: :reparent_to
  before_discard :remove_path

  REGION_TYPES = %w[root organization state district block facility].freeze
  enum region_type: REGION_TYPES.zip(REGION_TYPES).to_h, _suffix: "regions"

  REGION_TYPES.each do |type|
    # Our enum adds a pluralized suffix, which is nice for scopes, but weird for the question methods
    # with individual objects. So we define our own question methods here for a nicer API.
    define_method("#{type}_region?") do
      region_type == type
    end
    # Don't leave around the old, auto generated methods to avoid confusion
    undef_method "#{type}_regions?"
  end

  def self.root
    Region.find_by(region_type: :root)
  end

  def slug_candidates
    [
      :name,
      [:name, :region_type],
      [:name, :region_type, :short_uuid]
    ]
  end

  def short_uuid
    SecureRandom.uuid[0..7]
  end

  def assigned_patients
    Patient.where(assigned_facility: facilities)
  end

  def facilities
    if facility_region?
      Facility.where(id: source_id)
    else
      source_ids = facility_regions.pluck(:source_id)
      Facility.where(id: source_ids)
    end
  end

  # A label is a sequence of alphanumeric characters and underscores.
  # (In C locale the characters A-Za-z0-9_ are allowed).
  # Labels must be less than 256 bytes long.
  def path_label
    set_slug unless slug
    slug.gsub(/\W/, "_").slice(0, MAX_LABEL_LENGTH)
  end

  def log_payload
    attrs = attributes.slice("name", "slug", "path")
    attrs["id"] = id.presence
    attrs["region_type"] = region_type
    attrs["errors"] = errors.full_messages.join(",") if errors.any?
    attrs.symbolize_keys
  end

  REGION_TYPES.reject { |t| t == "root" }.map do |region_type|
    # Generates belongs_to type of methods to fetch a region's ancestor
    # e.g. facility.organization
    ancestor_method = "#{region_type}_region"
    define_method(ancestor_method) do
      if self_and_descendant_types(region_type).include?(self.region_type)
        self_and_ancestors.find_by(region_type: region_type)
      else
        raise NoMethodError, "undefined method #{region_type} for region '#{name}' of type #{self.region_type}"
      end
    end

    # Generates has_many type of methods to fetch a region's descendants
    # e.g. organization.facility_regions
    descendant_method = "#{region_type}_regions"
    define_method(descendant_method) do
      if ancestor_types(region_type).include?(self.region_type)
        descendants.where(region_type: region_type)
      else
        raise NoMethodError, "undefined method #{region_type.pluralize} for region '#{name}' of type #{self.region_type}"
      end
    end
  end

  private

  def initialize_path
    logger.info(class: self.class.name, msg: "got reparent_to: #{reparent_to.name}, going to initialize new path")
    self.path = if reparent_to.path.present?
      "#{reparent_to.path}.#{path_label}"
    else
      path_label
    end
    self.reparent_to = nil
  end

  def remove_path
    self.path = nil
  end

  def ancestor_types(region_type)
    REGION_TYPES.split(region_type).first
  end

  def descendant_types(region_type)
    REGION_TYPES.split(region_type).second
  end

  def self_and_ancestor_types(region_type)
    ancestor_types(region_type) + [region_type]
  end

  def self_and_descendant_types(region_type)
    [region_type] + descendant_types(region_type)
  end
end
