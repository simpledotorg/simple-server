require "ostruct"

class AdminAccessPresenter < SimpleDelegator
  attr_reader :current_admin

  def initialize(current_admin)
    @current_admin = current_admin
    super
  end

  def new_access_tree
    current_admin
      .access_tree(:manage)
      .fetch(:organizations)
  end

  def editable_access_tree(editable_user)
    current_admin
      .access_tree(:manage, reveal_access: false)
      .deep_merge(editable_user.access_tree(:view, reveal_access: true))
      .fetch(:organizations)
  end

  def viewable_access_tree(viewable_user)
    viewable_user
      .access_tree(:view)
      .fetch(:organizations)
  end

  def display_access_level
    OpenStruct.new(UserAccess::LEVELS.fetch(current_admin.access_level.to_sym))
  end

  def permitted_access_levels_info
    UserAccess::LEVELS
      .slice(*current_admin.permitted_access_levels)
      .map { |_level, info| info.values_at(:name, :id) }
  end
end
