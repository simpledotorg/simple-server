class FacilityPolicy < ApplicationPolicy
  def index?
    user.has_role?(
      :owner,
      :organization_owner,
      :supervisor,
      :analyst
    )
  end

  def show?
    user.owner? || (user.has_role?(:organization_owner, :analyst, :supervisor) && belongs_to_admin?)
  end

  def share_anonymized_data?
    user.owner?
  end

  def whatsapp_graphics?
    show?
  end

  def create?
    user.owner? || user.organization_owner?
  end

  def new?
    create?
  end

  def update?
    user.owner? || (user.organization_owner? && belongs_to_admin?)
  end

  def edit?
    update?
  end

  def destroy?
    destroyable? && (user.owner? || (user.organization_owner? && belongs_to_admin?))
  end

  def upload?
    user.owner?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.where(facility_group: user.facility_groups)
    end
  end

  private

  def destroyable?
    record.registered_patients.none? && record.blood_pressures.none?
  end

  def belongs_to_admin?
    user.facilities.include?(record)
  end

end
