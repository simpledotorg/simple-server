class DashboardPolicy < Struct.new(:user, :dashboard)

  def show?
    Pundit.policy(user, [:cohort_report, Organization]).index? || Pundit.policy(user, User).index?
  end

  def overdue_list?
    Pundit.policy(user, [:overdue_list, Appointment]).index?
  end

  def adherence_follow_up?
    Pundit.policy(user, [:adherence_follow_up, Patient]).index?
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