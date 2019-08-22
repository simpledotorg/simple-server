class OrganizationDistrictPolicy < ApplicationPolicy
  def index?
    user_permission_slugs = user.user_permissions.pluck(:permission_slug).map(&:to_sym)
    [:can_manage_all_organizations,
     :can_manage_an_organization,
     :can_manage_a_facility_group
    ].any? { |slug| user_permission_slugs.include? slug }
  end

  def show?
    user_has_any_permissions?(
      :can_manage_all_organizations,
      [:can_manage_an_organization, record.organization],
    )
  end

  def share_anonymized_data?
    user_has_any_permissions?(:can_manage_all_organizations)
  end

  def whatsapp_graphics?
    user.has_role?(:organization_owner, :supervisor) && user.organizations.include?(record.organization)
  end
end
