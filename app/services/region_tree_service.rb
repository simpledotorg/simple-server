class RegionTreeService
  attr_reader :org, :tree_map

  def initialize(org)
    @org = org
    preload_regions
  end

  def preload_regions
    @tree_map = Region.all.each_with_object({}) do |region, memo|
      memo[region.path] = region
    end
  end

  def fast_children(region)
    tree_map.keys.grep(/^#{region.path}\.[^.]+$/).map { |path| tree_map[path] }
  end
end
