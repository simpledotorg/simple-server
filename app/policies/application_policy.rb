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

  def user_has_any_roles?(*roles)
    roles.include? user.role.name
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

    def organization_ids_for_permission(slug)
      resources = resources_for_permission(slug)
      resources.map { |resource|
        if resource.is_a? Organization
          resource.id
        else
          resource.organization.id
        end
      }.uniq.compact
    end

    def facility_group_ids_for_permission(slug)
      resources = resources_for_permission(slug)
      resources.flat_map do |resource|
        if resource.is_a? Organization
          resource.facility_groups.map(&:id)
        elsif resource.is_a? FacilityGroup
          resource.id
        end
      end
    end

    def facility_ids_for_permission(slug)
      resources = resources_for_permission(slug)

      resources.flat_map { |resource|
        resource.facilities.map(&:id)
      }.uniq.compact
    end
  end
end
