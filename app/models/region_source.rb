# frozen_string_literal: true

module RegionSource
  def self.extended(klass)
    klass.has_one :region, inverse_of: :source, foreign_key: "source_id", autosave: true
    klass.after_discard do
      region&.discard
    end
    klass.define_method :clean_up_empty_regions do
      children = region.children
      if children.empty?
        logger.warn "Destroying region #{region.region_type} #{region.name} as it has no children and source #{self.class} #{name} is being destroyed"
        region.destroy!
      else
        logger.warn "Not destroying region #{region.region_type} #{region.name} still has children #{children.map(&:name)}"
      end
    end
    klass.before_destroy :clean_up_empty_regions
  end
end
