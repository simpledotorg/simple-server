class Reports::RegionTreeComponent < ViewComponent::Base
  attr_reader :parent, :children
  delegate :accessible_region?, to: :helpers

  def initialize(parent:, children:)
    @children = children
    @parent = parent
  end

  OFFSET = 2

  def accessible_region?(region)
    case region.region_type
    when "facility"
      true
    else
      helpers.accessible_region?(region)
    end
  end

  def depth(region)
    depth = Region::REGION_TYPES.index(region.region_type) - OFFSET
    depth += 1 if region.child_region_type.nil?
    depth
  end

  def render?
    children&.any?
  end
end
