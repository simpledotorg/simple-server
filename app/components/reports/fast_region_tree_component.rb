class Reports::FastRegionTreeComponent < ViewComponent::Base
  attr_reader :parent, :children

  def initialize(parent:, children:)
    @children = children
    @parent = parent
  end

  OFFSET = 2

  # Note that we short circuit facility access checks because they are handled in the controller, as they are the
  # leaf nodes that are returned via our accessible region view_reports finder. This avoids the many extra authz checks for
  # index view, which could be in the thousands for users with a lot of access.
  def accessible_region?(region, action)
    case region.region_type
    when "facility"
      true
    else
      helpers.accessible_region?(region, action)
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
