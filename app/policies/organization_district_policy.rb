class OrganizationDistrictPolicy < ApplicationPolicy
  def index?
    user.owner? || user.organization_owner?
  end

  def show?
    user.owner? || [:organization_owner, :supervisor, :analyst].map { |role| admin_can_access?(role) }.any?
  end

  private

  def admin_can_access?(role)
    user.role == role.to_s && user.facility_groups.include?(record)
  end
end
