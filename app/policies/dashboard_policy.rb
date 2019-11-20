class DashboardPolicy < Struct.new(:user, :dashboard)

  def show?
    Pundit.policy(user, [:cohort_report, Organization]).index? ||
      Pundit.policy(user, [:manage, :user, User]).index?
  end

  def overdue_list?
    Pundit.policy(user, [:overdue_list, Appointment]).index?
  end

  def adherence_follow_up?
    Pundit.policy(user, [:adherence_follow_up, Patient]).index?
  end

  def manage_organizations?
    Pundit.policy(user, [:manage, Organization]).index?
  end

  def manage_facilities?
    Pundit.policy(user, [:manage, :facility, Facility]).index?
  end

  def manage_protocols?
    Pundit.policy(user, [:manage, Protocol]).index?
  end

  def manage_admins?
    Pundit.policy(user, [:manage, :admin, User]).index?
  end

  def manage_users?
    Pundit.policy(user, [:manage, :user, User]).index?
  end

  def manage?
    [manage_organizations?,
     manage_facilities?,
     manage_protocols?,
     manage_admins?,
     manage_users?].any?
  end
end