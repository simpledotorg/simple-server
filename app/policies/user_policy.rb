class UserPolicy < ApplicationPolicy
  def index?
    user_permission_slugs = user.user_permissions.pluck(:permission_slug).map(&:to_sym)
    [:can_manage_all_users,
     :can_manage_users_for_organization,
     :can_manage_users_for_facility_group
    ].any? { |slug| user_permission_slugs.include? slug }
  end

  def show?
    user_has_any_permissions?(
      :can_manage_all_users,
      [:can_manage_users_for_organization, record.organization],
      [:can_manage_users_for_facility_group, record.facility_group])
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

  def create_user_for_invitation?
    update?
  end

  def new_user_for_invitation?
    create_user_for_invitation?
  end

  def assign_permissions?
    user.has_permission?(:can_manage_user_permissions)
  end

  def destroy?
    user_has_any_permissions?(
      :can_manage_all_users,
      [:can_manage_users_for_organization, record.organization],
      [:can_manage_users_for_facility_group, record.facility_group])
  end

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.has_permission?(:can_manage_all_users)
        scope.all
      elsif user.has_permission?(:can_manage_users_for_organization)
        facilities = resources_for_permission(:can_manage_users_for_organization).flat_map(&:facilities)
        scope.joins(:phone_number_authentications).where(phone_number_authentications: { facility: facilities })
      elsif user.has_permission?(:can_manage_users_for_facility_group)
        facilities = resources_for_permission(:can_manage_users_for_facility_group).flat_map(&:facilities)
        scope.joins(:phone_number_authentications).where(phone_number_authentications: { facility: facilities })
      else
        scope.none
      end
    end
  end
end
