class OrganizationDistrictPolicy < ApplicationPolicy
  def index?
    user.owner? || user.organization_owner?
  end

  def show?
    [:owner, :organization_owner, :supervisor, :analyst].include?(user.role.to_sym) &&
      user.organizations.include?(record.organization)
  end

  def share_anonymized_data?
    user.owner?
  end

  def whatsapp_graphics?
    user.owner? || (user.has_role?(:organization_owner, :supervisor) && user.organizations.include?(record.organization))
  end
end
