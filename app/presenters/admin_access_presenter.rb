class AdminAccessPresenter < SimpleDelegator
  attr_reader :current_admin

  def initialize(current_admin)
    @current_admin = current_admin
    super
  end

  def access_tree
    current_admin.access_tree(:manage)[:organizations]
  end

  def permitted_access_levels_info
    UserAccess::LEVELS
      .slice(*current_admin.permitted_access_levels)
      .map { |_level, info| info.values_at(:name, :id) }
  end
end
