class Reports::RegionTreeComponent < ViewComponent::Base
  attr_reader :parent, :children

  def initialize(parent:, children:)
    @children = children
    @parent = parent
  end

  OFFSET = 2

  def depth(region)
    depth = Region::REGION_TYPES.index(region.region_type) - OFFSET
    depth += 1 if region.child_region_type.nil?
    depth
  end

  def render?
    children&.any?
  end
end
