class UserPolicy < ApplicationPolicy
  def index?
    user_permission_slugs = user.user_permissions.pluck(:permission_slug).map(&:to_sym)
    [:approve_health_workers_for_all_organizations,
     :approve_health_workers_for_organization,
     :approve_health_workers_for_facility_group
    ].any? { |slug| user_permission_slugs.include? slug }
  end

  def show?
    user_has_any_permissions?(
      :approve_health_workers_for_all_organizations,
      [:approve_health_workers_for_organization, record.organization],
      [:approve_health_workers_for_facility_group, record.facility_group])
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
    user_has_any_permissions?(
      :manage_admins_for_all_organizations,
      [:manage_admins_for_organization, user.organization])
  end

  def new_user_for_invitation?
    create_user_for_invitation?
  end

  def assign_permissions?
    user.has_permission?(:manage_admins_for_all_organizations)
  end

  def destroy?
    user_has_any_permissions?(
      :approve_health_workers_for_all_organizations,
      [:approve_health_workers_for_organization, record.organization],
      [:approve_health_workers_for_facility_group, record.facility_group])
  end

  def user_can_invite_role(role)
    slugs = user.user_permissions.pluck(:permission_slug).map { |slug| slug.to_sym }
    roles_user_can_invite
      .slice(*slugs)
      .values
      .flat_map(&:itself)
      .include?(role.to_sym)
  end

  def roles_user_can_invite
    { manage_admins_for_all_organizations: [:owner, :supervisor, :analyst, :organization_owner, :counsellor],
      manage_admins_for_organization: [:supervisor, :analyst, :organization_owner, :counsellor] }
  end

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.has_permission?(:approve_health_workers_for_all_organizations)
        scope.all
      elsif user.has_permission?(:approve_health_workers_for_organization)
        facilities = resources_for_permission(:approve_health_workers_for_organization).flat_map(&:facilities)
        scope.joins(:phone_number_authentications).where(phone_number_authentications: { facility: facilities })
      elsif user.has_permission?(:approve_health_workers_for_facility_group)
        facilities = resources_for_permission(:approve_health_workers_for_facility_group).flat_map(&:facilities)
        scope.joins(:phone_number_authentications).where(phone_number_authentications: { facility: facilities })
      else
        scope.none
      end
    end
  end
end
