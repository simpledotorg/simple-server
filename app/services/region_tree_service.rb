class RegionTreeService
  attr_reader :org, :tree_map

  def initialize(org)
    @org = org
    @tree_map = preload_regions
    @ancestors = {}
  end

  def preload_regions
    Region.all.each_with_object({}) do |region, memo|
      memo[region.path] = region
    end
  end

  def with_facilities!(facilities)
    facilities_ancestors = self_and_all_ancestors_hash(facilities)
    @tree_map = tree_map.keys.each_with_object({}) do |path, memo|
      memo[path] = tree_map[path] if facilities_ancestors.key?(path)
    end
    self
  end

  def self_and_all_ancestors_hash(regions)
    regions.each_with_object({}) do |region, memo|
      memo.merge!(self_and_ancestors_hash(region))
    end
  end

  def self_and_ancestors_hash(region)
    current = region.path.split(".") # "org.state.district.block.facility" -> ["org", "state", "district", "block", "facility"]
    @ancestors = {}
    until current.empty?
      @ancestors[current.join(".")] = true
      current.pop
    end
    @ancestors
  end

  def fast_children(region)
    tree_map.keys.grep(/^#{region.path}\.[^.]+$/).map { |path| tree_map[path] }
  end
end
