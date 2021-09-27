module RegionSource
  def self.extended(klass)
    klass.has_one :region, inverse_of: :source, foreign_key: "source_id", autosave: true
    klass.after_discard do
      region&.discard
    end
    klass.define_method :clean_up_empty_regions do
      region.destroy! if region.children.none?
    end
    klass.before_destroy :clean_up_empty_regions
  end
end
