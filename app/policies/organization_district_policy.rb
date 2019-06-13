class OrganizationDistrictPolicy < ApplicationPolicy
  def index?
    user.owner? || user.organization_owner?
  end

  def show?
    [:owner, :organization_owner, :supervisor, :analyst].include?(user.role.to_sym)
  end

  def share_anonymized_data?
    [:owner, :organization_owner, :supervisor, :analyst].include?(user.role.to_sym)
  end
end
