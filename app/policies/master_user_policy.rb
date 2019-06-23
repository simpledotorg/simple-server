class MasterUserPolicy < ApplicationPolicy
  def index?
    user_permission_slugs = user.user_permissions.pluck(:permission_slug).map(&:to_sym)
    [:can_approve_all_users,
     :can_approve_users_for_organization,
     :can_approve_users_for_facility_group
    ].any? { |slug| user_permission_slugs.include? slug }
  end

  def user_belongs_to_admin?
    user.users.include?(record)
  end

  def show?
    user.owner? || user_belongs_to_admin?
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

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.has_permission?(:can_approve_all_users)
        return scope.all
      elsif user.has_permission?(:can_approve_users_for_organization)
        facilities = resources_for_permission(:can_approve_users_for_organization).flat_map(&:facilities)
        return scope.where(facility: facilities)
      elsif user.has_permission?(:can_approve_users_for_organization)
        facilities = resources_for_permission(:can_approve_users_for_organization).flat_map(&:facilities)
        return scope.where(facility: facilities)
      end

      scope.none
    end
  end
end
