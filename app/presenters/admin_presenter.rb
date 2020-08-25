require "ostruct"

class AdminPresenter < SimpleDelegator
  attr_reader :current_admin

  def initialize(current_admin)
    @current_admin = current_admin
    super
  end

  def permitted_access_levels_info
    UserAccess::LEVELS
      .slice(*current_admin.permitted_access_levels)
      .map { |_level, info| info.values_at(:name, :id) }
  end
end
