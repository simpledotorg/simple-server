class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def user_has_any_permissions?(*permissions)
    permissions.any? do |permission|
      if permission.is_a?(Array)
        user.authorized?(permission.first, resource: permission.second)
      else
        user.authorized?(permission)
      end
    end
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.all
    end

    private

    def resources_for_permission(permission_slug)
      user.user_permissions
        .where(permission_slug: permission_slug)
        .includes(:resource)
        .map(&:resource)
        .compact
    end
  end
end
