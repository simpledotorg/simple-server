module RegionSource
  def self.extended(klass)
    klass.has_one :region, as: :source, foreign_key: "source_id"
  # has_one :region, as: :source
    klass.after_discard do
      region&.discard
    end
  end
end
