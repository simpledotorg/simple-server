class DashboardPolicy < Struct.new(:user, :dashboard)
  def index?
    user.has_permission?(:view_cohort_reports)
  end

  def show?
    user.has_permission?(:view_cohort_reports)
  end

  def manage?
    management_permissions = [
      :approve_health_workers,
      :manage_facilities,
      :manage_facility_groups,
      :manage_protocols,
      :manage_organizations,
      :manage_admins
    ]

    user.user_permissions.where(permission_slug: management_permissions).present?
  end
end