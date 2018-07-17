class FacilityPolicy < ApplicationPolicy
  def index?
    user.admin? || user.supervisor?
  end

  def show?
    index?
  end
end
