class OrganizationDistrictPolicy < ApplicationPolicy
  def index?
    user.user_permissions
      .where(permission_slug: [:manage_organizations, :manage_facility_groups])
      .present?
  end

  def show?
    user_has_any_permissions?(
      [:manage_organizations, nil],
      [:manage_facility_groups, record.organization]
    )
  end

  def share_anonymized_data?
    user_has_any_permissions?(:manage_organizations)
  end

  def whatsapp_graphics?
    show?
  end

  def patient_list?
    whatsapp_graphics?
  end
end
