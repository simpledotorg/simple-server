class DashboardPolicy < Struct.new(:user, :dashboard)
  def show?
    user.owner? || user.supervisor? || user.analyst?
  end
end
