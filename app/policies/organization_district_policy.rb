class OrganizationDistrictPolicy < ApplicationPolicy
  def index?
    user_permission_slugs = user.user_permissions.pluck(:permission_slug).map(&:to_sym)
    [:manage_organizations,
     :manage_facility_groups_for_organization,
     :manage_facilities_for_facility_group
    ].any? { |slug| user_permission_slugs.include? slug }
  end

  def show?
    user_has_any_permissions?(
      :manage_organizations,
      [:manage_facility_groups_for_organization, record.organization],
    )
  end

  def share_anonymized_data?
    user_has_any_permissions?(:manage_organizations)
  end

  def whatsapp_graphics?
    show?
  end
end
