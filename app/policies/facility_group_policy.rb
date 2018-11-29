class FacilityGroupPolicy < ApplicationPolicy
  def index?
    user.owner? || user.supervisor?
  end

  def show?
    index?
  end
end