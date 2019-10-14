class UserPolicy < ApplicationPolicy
  def index?
    user.user_permissions
      .where(permission_slug: :approve_health_workers)
      .present?
  end

  def show?
    user_has_any_permissions?(
      [:approve_health_workers, nil],
      [:approve_health_workers, record.organization],
      [:approve_health_workers, record.facility_group])
  end

  def update?
    show?
  end

  def edit?
    update?
  end

  def disable_access?
    update?
  end

  def enable_access?
    update?
  end

  def reset_otp?
    update?
  end

  def destroy?
    user_has_any_permissions?(
      [:approve_health_workers, nil],
      [:approve_health_workers, record.organization],
      [:approve_health_workers, record.facility_group])
  end

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.has_permission?(:approve_health_workers)
        scope.joins(:phone_number_authentications)
          .where(phone_number_authentications:
                   { facility_id: facility_ids_for_slug(:approve_health_workers) })
      end

      scope.none
    end

    def facility_ids_for_slug(slug)
      resources = resources_for_permission(slug)

      resources.flat_map do |resource|
        resource.facilities.map(&:id)
      end.uniq.compact
    end
  end
end
