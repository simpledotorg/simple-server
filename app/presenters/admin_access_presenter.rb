class AdminAccessPresenter < SimpleDelegator
  attr_reader :admin

  def initialize(admin)
    @admin = admin
    super
  end

  def permitted_access_levels_info
    UserAccess::LEVELS
      .slice(*admin.permitted_access_levels)
  end

  def access_tree
    current_admin.access_tree(:manage)[:organizations]
  end
end
