class Manage::Facility::FacilityPolicy < ApplicationPolicy
  def index?
    user.user_permissions
      .where(permission_slug: [:manage_facilities, :manage_facility_groups])
      .present?
  end

  def show?
    user_has_any_permissions?(
      [:manage_facilities, nil],
      [:manage_facilities, record.organization],
      [:manage_facilities, record.facility_group]
    )
  end

  def share_anonymized_data?
    user_has_any_permissions?([:manage_organizations, nil])
  end

  def create?
    user_has_any_permissions?(
      [:manage_facilities, nil],
      [:manage_facilities, record.organization],
      [:manage_facilities, record.facility_group]
    )
  end

  def new?
    create?
  end

  def update?
    create?
  end

  def edit?
    update?
  end

  def destroy?
    destroyable? && create?
  end

  def upload?
    user.user_permissions
      .where(permission_slug: [:manage_facilities])
      .present?
  end

  def destroyable?
    record.registered_patients.none? && record.blood_pressures.none?
  end

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none unless user.has_permission?([:manage_facilities, :manage_facility_groups])

      facility_ids = facility_ids_for_permission([:manage_facilities, :manage_facility_groups])
      return scope.all if facility_ids.empty?

      scope.where(id: facility_ids)
    end
  end
end
