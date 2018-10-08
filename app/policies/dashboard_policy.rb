class DashboardPolicy < Struct.new(:user, :dashboard)
  def show?
    user.owner? || user.supervisor?
  end
end
